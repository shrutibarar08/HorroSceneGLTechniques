#ifndef HORROSCENEGLTECHNIQUES_ISYSTEM_H
#define HORROSCENEGLTECHNIQUES_ISYSTEM_H

#include <sal.h>
#include <cstdint>

namespace Engine
{
    typedef struct SYSTEM_CREATE_DESC
    {
        void* Payload{};
    } SYSTEM_CREATE_DESC;

    typedef struct FRAME_DESC
    {
        float DeltaTime  {};
        float ElapsedTime{};
        void* Payload    {};
    } FRAME_DESC;

    class __declspec(novtable) ISystem
    {
    public:
        virtual ~ISystem() noexcept = default;

        ISystem(const ISystem&) = delete;
        ISystem(ISystem&&)      = delete;

        ISystem& operator=(const ISystem&) = delete;
        ISystem& operator=(ISystem&&)      = delete;

        __checkReturn _NODISCARD __success(return != false)
        virtual bool Initialize (_In_ const SYSTEM_CREATE_DESC& desc) = 0;

        __checkReturn _NODISCARD __success(return != false)
        virtual bool UpdateBegin(_In_ const FRAME_DESC& desc)         = 0;

        virtual void UpdateEnd() = 0;
        virtual void Terminate() = 0;

        virtual const char* Name() const noexcept = 0;
        virtual std::uint32_t Version() const noexcept { return 0x00010000u; }

        virtual void SubscribeEvents() = 0;
    };
}

#endif //HORROSCENEGLTECHNIQUES_ISYSTEM_H
