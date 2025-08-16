#ifndef HORROSCENEGLTECHNIQUES_SINGLETON_H
#define HORROSCENEGLTECHNIQUES_SINGLETON_H
#pragma once

#include <sal.h>
#include <mutex>
#include <memory>
#include <utility>
#include <stdexcept>

template<typename T>
class ISingleton
{
public:
    ISingleton(const ISingleton&) = delete;
    ISingleton(ISingleton&&)      = delete;

    ISingleton& operator=(const ISingleton&) = delete;
    ISingleton& operator=(ISingleton&&)      = delete;

    template<typename... TArgs>
    __checkReturn _NODISCARD __success(s_pInstance != nullptr)
    static T& Get(_In_ TArgs&&... args)
    {
        std::call_once(s_onceFlag, [&]()
        {
            s_pInstance = std::make_unique<T>(std::forward<TArgs>(args)...);
        });

        if (s_pInstance == nullptr)
        {
#if defined(_DEBUG) || defined(DEBUG)
            __debugbreak();
#else
            throw std::runtime_error("Singleton instance not constructed");
#endif
        }
        return *s_pInstance;
    }

    static void Destroy() noexcept
    {
        s_pInstance.reset();
    }

protected:
    ISingleton()          = default;
    ~ISingleton()         = default;

private:
    inline static std::unique_ptr<T> s_pInstance{};
    inline static std::once_flag     s_onceFlag{};
};

#endif // HORROSCENEGLTECHNIQUES_SINGLETON_H
