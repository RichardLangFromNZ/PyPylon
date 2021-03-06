from libcpp cimport bool
from libc.stdint cimport uint32_t, uint64_t, int64_t
from libcpp.string cimport string

cdef extern from "Base/GCBase.h":
    cdef cppclass gcstring:
        gcstring(char*)

cdef extern from "GenApi/GenApi.h" namespace 'GenApi':

    ctypedef enum EInterfaceType:
        intfIValue,
        intfIBase,
        intfIInteger,
        intfIBoolean,
        intfICommand,
        intfIFloat,
        intfIString,
        intfIRegister,
        intfICategory,
        intfIEnumeration,
        intfIEnumEntry,
        intfIPort

    cdef cppclass INode:
        gcstring GetName(bool FullQualified=False)
        gcstring GetNameSpace()
        gcstring GetDescription()
        gcstring GetDisplayName()
        bool IsFeature()
        gcstring GetValue()
        EInterfaceType GetPrincipalInterfaceType()


    # Types an INode could be
    cdef cppclass IValue:
        gcstring ToString()
        void FromString(gcstring, bool verify=True) except +

    cdef cppclass IBoolean:
        bool GetValue()
        void SetValue(bool) except +

    cdef cppclass IInteger:
        int64_t GetValue()
        void SetValue(int64_t) except +
        int64_t GetMin()
        int64_t GetMax()

    cdef cppclass IString
    cdef cppclass IFloat:
        double GetValue()
        void SetValue(double) except +
        double GetMin()
        double GetMax()

    cdef cppclass ICommand:
        void Execute() except +
        bool IsDone() except +


    cdef cppclass NodeList_t:
        cppclass iterator:
            INode* operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        NodeList_t()
        CDeviceInfo& operator[](int)
        CDeviceInfo& at(int)
        iterator begin()
        iterator end()

    cdef cppclass ICategory

    cdef cppclass INodeMap:
        void GetNodes(NodeList_t&)
        INode* GetNode(gcstring& )
        uint32_t GetNumNodes()

cdef extern from *:
    IValue* dynamic_cast_ivalue_ptr "dynamic_cast<GenApi::IValue*>" (INode*) except +
    IBoolean* dynamic_cast_iboolean_ptr "dynamic_cast<GenApi::IBoolean*>" (INode*) except +
    IInteger* dynamic_cast_iinteger_ptr "dynamic_cast<GenApi::IInteger*>" (INode*) except +
    IFloat* dynamic_cast_ifloat_ptr "dynamic_cast<GenApi::IFloat*>" (INode*) except +
    ICommand* dynamic_cast_icommand_ptr "dynamic_cast<GenApi::ICommand*>" (INode*) except +
    INodeMap* dynamic_cast_inodemap_ptr "dynamic_cast<GenApi::INodeMap*>" (INode*) except +
    ICategory* dynamic_cast_icategory_ptr "dynamic_cast<GenApi::ICategory*>" (INode*) except +

    bool node_is_readable "GenApi::IsReadable" (INode*) except +
    bool node_is_writable "GenApi::IsWritable" (INode*) except +
    bool node_is_implemented "GenApi::IsImplemented" (INode*) except +

cdef extern from "pylon/PylonIncludes.h" namespace 'Pylon':
    # Common special data types
    cdef cppclass String_t
    cdef cppclass StringList_t

    cdef enum EPayloadType:
        PayloadType_Undefined,
        PayloadType_Image,
        PayloadType_RawData,
        PayloadType_File,
        PayloadType_ChunkData,
        PayloadType_DeviceSpecific


    # Top level init functions
    void PylonInitialize() except +
    void PylonTerminate() except +

    cdef cppclass IImage:
        uint32_t GetWidth()
        uint32_t GetHeight()
        size_t GetPaddingX()
        size_t GetImageSize()
        void* GetBuffer()
        bool IsValid()


    # NOTE: We don't bother providing cython import definition for CGrabResultData class as the only way that CGrabResultPtr provides
    # for accessing its underlying data is with a -> operator override, which cython doesn't support.  Instead have to use the
    # assorted ACCESS_CGrabResultPtr_xxx functions

    cdef cppclass CGrabResultPtr:
        IImage& operator()


    cdef cppclass IPylonDevice:
        pass

    cdef cppclass CDeviceInfo:
        String_t GetSerialNumber() except +
        String_t GetUserDefinedName() except +
        String_t GetModelName() except +
        String_t GetDeviceVersion() except +
        String_t GetFriendlyName() except +
        String_t GetVendorName() except +
        String_t GetDeviceClass() except +

    cdef enum EGrabStrategy:
        GrabStrategy_OneByOne,
        GrabStrategy_LatestImageOnly,
        GrabStrategy_LatestImages,
        GrabStrategy_UpcomingImage

    cdef cppclass CInstantCamera:
        CInstantCamera()
        void Attach(IPylonDevice*)
        CDeviceInfo& GetDeviceInfo() except +
        void IsCameraDeviceRemoved()
        void Open() except +
        void Close() except +
        void StopGrabbing() except +
        bool IsOpen() except +
        IPylonDevice* DetachDevice() except +
        void StartGrabbing(EGrabStrategy strategy) except +
        void StartGrabbing(size_t maxImages, EGrabStrategy strategy) except +
        bool IsGrabbing()
        # RetrieveResult() is blocking call into C++ native SDK, allow it to be called without GIL
        bool RetrieveResult(unsigned int timeout_ms, CGrabResultPtr& grab_result) nogil except + # FIXME: Timout handling
        INodeMap& GetNodeMap()

        # From CInstantCameraParams_Params base class
        IInteger &MaxNumBuffer;
        IInteger &MaxNumQueuedBuffer;
        IInteger &OutputQueueSize;






    cdef cppclass DeviceInfoList_t:
        cppclass iterator:
            CDeviceInfo operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        DeviceInfoList_t()
        CDeviceInfo& operator[](int)
        CDeviceInfo& at(int)
        iterator begin()
        iterator end()

    cdef cppclass CTlFactory:
        int EnumerateDevices(DeviceInfoList_t&, bool add_to_list=False)
        IPylonDevice* CreateDevice(CDeviceInfo&)

# Hack to define a static member function
cdef extern from "pylon/PylonIncludes.h"  namespace 'Pylon::CTlFactory':
    CTlFactory& GetInstance()

# EVIL HACK: Cython does not support the -> deference operator, however the only public interface that CGrabResultPtr smart
# pointer provides to its underlying CGrabResultData object is with a -> operator override.  As an alternative have to use
# bundle of helper macros from "hacks.h" to get at CGrabResultData members

cdef extern from 'hacks.h':
    bool ACCESS_CGrabResultPtr_GrabSucceeded(CGrabResultPtr ptr)
    String_t ACCESS_CGrabResultPtr_GetErrorDescription(CGrabResultPtr ptr)
    uint32_t ACCESS_CGrabResultPtr_GetErrorCode(CGrabResultPtr ptr)
    EPayloadType ACCESS_CGrabResultPtr_GetPayloadType(CGrabResultPtr ptr)
    INodeMap& ACCESS_CGrabResultPtr_GetChunkDataNodeMap(CGrabResultPtr ptr)



