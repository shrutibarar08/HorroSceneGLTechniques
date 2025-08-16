#ifndef HORROSCENEGLTECHNIQUES_EVENT_BUS_H
#define HORROSCENEGLTECHNIQUES_EVENT_BUS_H

#include <sal.h>
#include <cstdint>
#include <deque>
#include <unordered_map>
#include <vector>
#include <utility>
#include <type_traits>

namespace Engine
{
    namespace detail
    {
        using ID        = std::uint32_t;
        using EventType = std::uint64_t;
        using EventCallbackFn = void(*)(_In_ const void* payload, _In_opt_ void* listener);

        // 64-bit FNV-1a
        constexpr EventType FNV1A64(const char* s) noexcept
        {
            EventType h = 1469598103934665603ull;
            while (*s)
            {
                h ^= static_cast<unsigned char>(*s++);
                h *= 1099511628211ull;
            }
            return h;
        }

        template<typename T>
        constexpr EventType TypeIdOf() noexcept
        {
            return FNV1A64(__FUNCSIG__); // stable on MSVC
        }
    }

    // ~ Subscription token
    typedef struct SUBSCRIPTION_TOKEN_DESC
    {
        detail::EventType Type{};
        detail::ID        Id{};
    } SUBSCRIPTION_TOKEN_DESC;

    // ~ Event record (type-erased)
    typedef struct EVENT_RECORD_DESC
    {
        detail::EventType Type             {};
        void*             Payload          {};
        void              (*Deleter)(void*){}; // deletes payload
        void*             Source           {};
    } EVENT_RECORD_DESC;

    // ~ Per-type subscriber slot
    typedef struct SUBSCRIBE_SLOT_DESC
    {
        detail::ID              Id      {};
        void*                   Listener{};
        detail::EventCallbackFn Fn      {};
    } SUBSCRIBE_SLOT_DESC;

    class EventBus
    {
    public:
        static EventBus& Instance() noexcept
        {
            static EventBus s_instance;
            return s_instance;
        }

        EventBus(const EventBus&) = delete;
        EventBus(EventBus&&)      = delete;

        EventBus& operator=(const EventBus&) = delete;
        EventBus& operator=(EventBus&&)      = delete;

        /// Subscribe to a specific TEvent. Returns a token to unsubscribe.
        template<typename TEvent>
        __checkReturn _NODISCARD
        SUBSCRIPTION_TOKEN_DESC Subscribe(
            _In_opt_ void* listener,
            _In_     void(*fn)(_In_ const TEvent&, _In_opt_ void*)
        )
        {
            const detail::EventType type = detail::TypeIdOf<TEvent>();
            auto& vec = m_mapSubscribers[type];
            const detail::ID newID = m_nNextId++;

            vec.emplace_back(SUBSCRIBE_SLOT_DESC{
                newID,
                listener,
                +[fn](_In_ const void* p, _In_opt_ void* self)
                {
                    const TEvent& ev = *static_cast<const TEvent*>(p);
                    fn(ev, self);
                }
            });

            return { type, newID };
        }

        /// Unsubscribe using the token
        void Unsubscribe(_In_ const SUBSCRIPTION_TOKEN_DESC& token)
        {
            auto it = m_mapSubscribers.find(token.Type);
            if (it == m_mapSubscribers.end())
            {
                return;
            }

            auto& vec = it->second;
            for (std::size_t i = 0; i < vec.size(); ++i)
            {
                if (vec[i].Id == token.Id)
                {
                    vec.erase(vec.begin() + static_cast<long>(i));
                    break;
                }
            }

            if (vec.empty())
            {
                m_mapSubscribers.erase(it);
            }
        }

        /// Post a copy of the event payload
        template <typename T>
        void Post(_In_ const T& ev, _In_opt_ void* source = nullptr)
        {
            const detail::EventType type = detail::TypeIdOf<T>();
            T* copy = new T(ev);
            m_qPending.emplace_back(EVENT_RECORD_DESC{
                type,
                copy,
                +[](void* p){ delete static_cast<T*>(p); },
                source
            });
        }

        /// Emplace-construct an event
        template <typename T, typename... Args>
        void Emplace(_In_opt_ void* source, Args&&... args)
        {
            const detail::EventType type = detail::TypeIdOf<T>();
            T* obj = new T(std::forward<Args>(args)...);
            m_qPending.emplace_back(EVENT_RECORD_DESC{
                type,
                obj,
                +[](void* p){ delete static_cast<T*>(p); },
                source
            });
        }

        /// Dispatch all queued events to current subscribers
        void DispatchAll()
        {
            std::deque<EVENT_RECORD_DESC> queue;
            queue.swap(m_qPending);

            while (!queue.empty())
            {
                EVENT_RECORD_DESC ev = queue.front();
                queue.pop_front();

                auto it = m_mapSubscribers.find(ev.Type);
                if (it != m_mapSubscribers.end())
                {
                    const auto snapshot = it->second; // stable copy during callbacks
                    for (const auto& sub : snapshot)
                    {
                        if (sub.Fn)
                        {
                            sub.Fn(ev.Payload, sub.Listener);
                        }
                    }
                }

                if (ev.Deleter)
                {
                    ev.Deleter(ev.Payload);
                }
            }
        }

        /// Optional: clear all subscribers and pending events (e.g., on shutdown)
        void Clear() noexcept
        {
            // drain pending
            for (auto& ev : m_qPending)
            {
                if (ev.Deleter)
                {
                    ev.Deleter(ev.Payload);
                }
            }
            m_qPending.clear();
            m_mapSubscribers.clear();
            m_nNextId = 1;
        }

        // Helper: type id for T (for debugging/telemetry)
        template <typename T>
        static constexpr detail::EventType TypeId()
        {
            return detail::TypeIdOf<T>();
        }

    private:
        EventBus() = default;
        ~EventBus() = default;

    private:
        std::unordered_map<detail::EventType, std::vector<SUBSCRIBE_SLOT_DESC>> m_mapSubscribers{};
        std::deque<EVENT_RECORD_DESC> m_qPending{};
        detail::ID m_nNextId{1};
    };

    // ----- Bind macro: listener class + event type + method -----
    #define EVENT_BIND_EVENT(_ClassType, _EventType, _Method) \
    +[](_In_ const _EventType& e, _In_opt_ void* self) \
    { \
        static_cast<_ClassType*>(self)->_Method(e); \
    }

    // Subscribe macro (returns a token)
    #define SUB_TO_EVENT(eventType, instance, method) \
    Engine::EventBus::Instance().Subscribe<eventType>( \
    instance, EVENT_BIND_EVENT(instance, eventType, method) \
    )

    // Unsubscribe macro (uses token)
    #define UNSUB_FROM_EVENT(token) \
    Engine::EventBus::Instance().Unsubscribe(token)

} // namespace Engine

#endif // HORROSCENEGLTECHNIQUES_EVENT_BUS_H
