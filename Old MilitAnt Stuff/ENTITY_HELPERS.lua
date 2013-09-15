--- ENTITY_HELPERS from C++.

--[[
--
--
-- EntityHelpers.h
--
--
#ifndef _ENTITY_HELPERS
#define _ENTITY_HELPERS

#include "AppUtils.h"
#include "Enum.h"

// Forward references
struct lua_State;

/// Builds a group of enums from comma-separated-value strings, with key lookup support
/// @param arr Array of <enum name, CSV string> associative pairs
template<int count> void BuildEnumGroup (AssocPair (&arr)[count])
{
	for (int i = 0; i < count; ++i) Enum_cl::GetMe()->Create(arr[i].mK, true).AddFromSVS(arr[i].mV);

	Enum_cl::GetMe()->Close();
}

/// Auxiliary type to build an enum group
template<int> struct AuxBuildGroup {
	template<int count> AuxBuildGroup (AssocPair (&arr)[count]) { BuildEnumGroup(arr); }
};

/// Helper to set up a group of enums via an internal static class constructor
#define STATIC_ENUM_GROUP(name, ...)																\
	static AssocPair name##_enums[] = { __VA_ARGS__ };												\
																									\
	static AuxBuildGroup<sizeof(name##_enums) / sizeof(AssocPair)> sBuilder_##name(name##_enums);

/// Reports if this is the first instance (e.g. since startup) and then flags the condition to avoid future alerts
/// @param bNotFirst [in-out] Condition flag, should initially be @b false; if @b false, set to @b true
/// @return If @a bNotFirst was @b false, returns @b true; otherwise @b false
inline bool IsFirstInstance (bool & bNotFirst)
{
	bool is_first = !bNotFirst;

	if (!bNotFirst) bNotFirst = true;

	return is_first;
}

/// Reports if this is the first instance (e.g. since startup) and then flags the condition bit to avoid future alerts
/// @param flags [in-out] Flag bits, bit @a bit should initially be clear; if clear, set it
/// @param bit Bit index
/// @return If bit @a bit was clear, returns @b true; otherwise @b false
template<int bit_count> inline bool IsFirstInstance (VTBitfield<bit_count> & flags, int bit)
{
	bool is_first = !flags.IsBitSet(bit);

	if (is_first) flags.SetBit(bit);

	return is_first;
}

/// Helper to send a @b ID_OBJECT_NEW_INSTANCE message to an object, e.g. to use static state in @b MessageFunction(); @e iParamA will be @b FALSE
/// @param object New instance
inline void OnNewInstance (VisTypedEngineObject_cl * object)
{
	Vision::Game.SendMsg(object, ID_OBJECT_NEW_INSTANCE, FALSE);
}

/// Variant that will use @e iParamA = @b TRUE, if this was the first instance
/// @param object New instance
/// @param bNotFirst [in-out] Condition flag, should initially be @b false; if  @b false, set to @b true
inline void OnNewInstance (VisTypedEngineObject_cl * object, bool & bNotFirst)
{
	Vision::Game.SendMsg(object, ID_OBJECT_NEW_INSTANCE, IsFirstInstance(bNotFirst) ? TRUE : FALSE);
}

///
/// @param pObject
/// @param ptr [out]
/// @param name
/// @param flags
template<typename T> void AssignNamedComponent (VisTypedEngineObject_cl * pObject, VSmartPtr<T> & ptr, const char * name, int flags = VIS_OBJECTCOMPONENTFLAG_NONE)
{
	//
	if (Vision::Editor.IsInEditor()) ptr = new T(name, flags);
	
	else ptr = FindComponentByName<T>(pObject, name);

	//
	if (ptr)
	{
		ptr->Initialize();
	
		pObject->AddComponent(ptr);
	}
}

///
/// @param pObject
/// @param name
/// @return
template<typename C> C * FindComponentByName (VisTypedEngineObject_cl * pObject, const char * name)
{
	int id = IVObjectComponent::LookupStringID(name);

	if (id != 0) return (C *)pObject->Components().GetComponentByID(id, C::GetClassTypeId());

	return NULL;
}

/// Templated variant of NativePtr()
template<typename T> T * NativePtrT (lua_State * L, int index)
{
	VisTypedEngineObject_cl * pObject = NativePtr(L, index);

	VASSERT(pObject->IsOfType(T::GetClassTypeId()));

	return (T *)pObject;
}

/// Loads a bitfield from an archive
/// @param ar Source archive
/// @param bitfield Bitfield to load
template<int bit_count> void LoadBitfield (VArchive & ar, VTBitfield<bit_count> & bitfield)
{
	VASSERT(!ar.IsLoading());

	for (int i = 0; i < bitfield.GetIntCount(); ++i) ar >> bitfield.GetIntArray()[i];
}

/// Loads a 3-vector of some kind from an archive
/// @param ar Source archive
/// @param vvar [out] Vector to load
template<typename T> void LoadVectorVar (VArchive & ar, T (&vvar)[3])
{
	VASSERT(ar.IsLoading());

	for (int i = 0; i < 3; ++i) ar >> vvar[i];
}

/// Resolves a group of unique ID's to loaded objects
/// @param objects [out] Objects loaded from ID's
/// @param id_array Array of unique ID's
template<typename T> void ResolveObjectIDs (VPListT<T> & objects, const DynArray_cl<__int64> & id_array)
{
	objects.EnsureCapacity(id_array.GetSize());

	for (size_t i = 0, n = id_array.GetSize(); i < n; ++i)
	{
		__int64 id = id_array.GetDataPtr()[i];

		if (id)
		{
			T * pObject = VisElementManager_cl<T *>::FindByUniqueID(id);

			VASSERT(pObject);

			objects.Append(pObject);
		}
	}
}

/// Saves a bitfield to an archive
/// @param ar [out] Target archive
/// @param bitfield Bitfield to save
template<int bit_count> void SaveBitfield (VArchive & ar, const VTBitfield<bit_count> & bitfield)
{
	VASSERT(!ar.IsLoading());

	for (int i = 0; i < bitfield.GetIntCount(); ++i) ar << bitfield.GetIntArray()[i];
}

/// Saves a 3-vector of some kind to an archive
/// @param ar [out] Target archive
/// @param vvar Vector to save
template<typename T> void SaveVectorVar (VArchive & ar, const T (&vvar)[3])
{
	VASSERT(!ar.IsLoading());

	for (int i = 0; i < 3; ++i) ar << vvar[i];
}

/// Gets a bit; internally, the bit is then flipped
/// @param flags [in-out] Flag bits
/// @param bit Bit to get and flip
/// @return If true, bit was set
template<int bit_count> bool GetBit_Flip (VTBitfield<bit_count> & flags, int bit)
{
	bool cur = flags.IsBitSet(bit);

	cur ? flags.RemoveBit(bit) : flags.SetBit(bit);

	return cur;
}

/// Tests whether a bit is clear; if so, sets it
/// @param flags [in-out] Flag bits
/// @param bit Bit to test / set
/// @return If true, bit was clear
template<int bit_count> bool IsBitClear_Flip (VTBitfield<bit_count> & flags, int bit)
{
	if (flags.IsBitSet(bit)) return false;

	flags.SetBit(bit);

	return true;
}

/// Tests whether a bit is set; if so, clears it
/// @param flags [in-out] Flag bits
/// @param bit Bit to test / clear
/// @return If true, bit was set
template<int bit_count> bool IsBitSet_Flip (VTBitfield<bit_count> & flags, int bit)
{
	if (!flags.IsBitSet(bit)) return false;

	flags.RemoveBit(bit);

	return true;
}

/// Variant of BeginVersionedSerialize() that begins with base object serialization
/// @remark Type should be explicit base type to avoid recursive serialization
template<typename T> char BeginVersionedSerialize (T * pObject, VArchive & ar, char iLocalVersion)
{
	pObject->T::Serialize(ar);

	return BeginVersionedSerialize(ar, iLocalVersion);
}

/// 
/// @param iParam
/// @param id
/// @param custom_message
template<typename T> T * EnsureEntity (INT_PTR iParam, __int64 id, const char * custom_message)
{
	VASSERT(T::GetClassId()->IsDerivedFrom(V_RUNTIME_CLASS(VisBaseEntity_cl)));

	if (!custom_message) custom_message = "%s";

	VisBaseEntity_cl * pEntity = id ? VisBaseEntity_cl::FindByUniqueID(id) : NULL;

	if (!pEntity) FailValidation(iParam, custom_message, "Entity missing");

	else if (!pEntity->IsOfType(T::GetClassId())) FailValidation(iParam, custom_message, "Entity fails to match type");

	else return (T *)pEntity;

	return NULL;
}

void AddEnumOp (lua_State * L, int op, const char * enum_name);
void CallFromStack (lua_State * L, int func_pos, int retc = 0);
void CopyComponents (const VisTypedEngineObject_cl * pFrom, VisTypedEngineObject_cl * pTo, VType * pBaseType = NULL);
void FailValidation (INT_PTR iParam, const char * message, ...);
void ManageObjectID (VisObject3D_cl * pObject, DynArray_cl<__int64> & id_array, bool bRemove);
void ManageTypeLink (int iID, INT_PTR iParam, VType * pType, bool * pbLinked = NULL);
void ManageTypeLinkID (int iID, INT_PTR iParam, VType * pType, __int64 & id);
void PopulateDropdownFromLuaArray (lua_State * L, INT_PTR iParam, const char * key, int t = -1);
void PopulateDropdownFromLuaTableKeys (lua_State * L, INT_PTR iParam, const char * key, int t = -1);
void PushFirstArgs (lua_State * L, void * key, const char * name, VisTypedEngineObject_cl * pObject, bool bIsProxy);
void RegisterCollectionAndContext (lua_State * L, const VType * pType, const char * name, bool bZoneBased = true);

bool FindSubstring (const char * str, VString & substr, int which, char separator = '.');
bool IsCommitted (VisTypedEngineObject_cl * pObject);
bool IsFlagClear_Flip (bool & bFlag);
bool IsFlagSet_Flip (bool & bFlag);
bool SplitString (const char * str, VString & prefix, VString & rest, char separator = '.');

int BindAndPushFuncRef (lua_State * L, bool & bHasBound, const char * name);
int CountComponents (const VisTypedEngineObject_cl * pObject, VType * pBaseType = NULL);
int CountComponents (const VObjectComponentCollection & comps, VType * pBaseType = NULL);
int CountSubstrings (const char * str, char separator = '.');

char BeginVersionedSerialize (VArchive & ar, char iLocalVersion);
char BeginComponentSerialize (IVObjectComponent * pComp, VArchive & ar, char iLocalVersion);
char BeginEntitySerialize (VisBaseEntity_cl * pEntity, VArchive & ar, char iLocalVersion);

VisTypedEngineObject_cl * NativePtr (lua_State * L, int index);
VisTypedEngineObject_cl * GetObjectByKey (const char * what, const char * key);

VisPath_cl * EnsurePath (INT_PTR iParam, __int64 id, const char * custom_message);

const VStaticString<MAX_VARNAME_LEN + 1> & GetEnumValue (VisTypedEngineObject_cl * pObject, const char * name, int num);

#endif
--]]

--[[
--
--
-- EntityHelpers.cpp
--
--
#include "stdafx.h"
#include "game.h"
#include "entityhelpers.h"
#include "entitymanager.h"
#include "Lua_/Lua.h"
#include "Lua_/Arg.h"
#include "Lua_/Helpers.h"

/// Adds an enum op to the stack
/// @param op Index of operation
/// @param enum_name Enumeration in which op is to be found
/// @remark Key left on stack
void AddEnumOp (lua_State * L, int op, const char * enum_name)
{
	const char * key = Enum_cl::GetMe()->GetKey(enum_name, op);

	lua_pushstring(L, key);	// ..., key

	Enum_cl::GetMe()->Close();
}

///
/// @param func_pos
/// @param retc
void CallFromStack (lua_State * L, int func_pos, int retc)
{
	if (Lua::PCall_EF(L, lua_gettop(L) - func_pos, retc) != 0)
	{
		Game_cl::GetMe()->TrapError(Lua::S(L,-1));

		lua_pop(L, 1);	// ...
	}
}

///
/// @param pFrom
/// @param pTo
/// @param pBaseType
void CopyComponents (const VisTypedEngineObject_cl * pFrom, VisTypedEngineObject_cl * pTo, VType * pBaseType)
{
	VASSERT(pFrom);
	VASSERT(pTo);
	VASSERT(!pBaseType || pBaseType->IsDerivedFrom(V_RUNTIME_CLASS(IVObjectComponent)));

	if (pFrom == pTo) return;

	VMemoryStreamPtr mem_stream = new VMemoryStream("Components");

	// Copy each desired component's state into memory, caching the type as well. Hide
	// the component's owner during the copy, so that it gets deserialized as an orphan.
	VMemoryOutStream ostream(Vision::File.GetManager(), mem_stream);

	VArchive ar_out("Components:Saving", &ostream, Vision::GetTypeManager());

	DynArray_cl<VType *> types(pFrom->Components().Count());

	int count = 0;

	for (int i = 0; i < pFrom->Components().Count(); ++i)
	{
		IVObjectComponent * pComp = pFrom->Components().GetPtrs()[i];

		if (!pComp || (pBaseType && !pComp->IsOfType(pBaseType))) continue;

		VisTypedEngineObject_cl * pOwner = pComp->GetOwner();

		pComp->m_pOwner = NULL;

		pComp->Serialize(ar_out);

		pComp->m_pOwner = pOwner;

		types[count++] = pComp->GetTypeId();
	}

	ar_out.Close();

	// Iterate through the types in order, creating an instance and feeding it the state
	// read back out of memory. In this way, a clean copy of the component is made; add
	// this to the target object.
	VMemoryInStream istream(Vision::File.GetManager(), mem_stream);

	VArchive ar_in("Components:Loading", &istream, Vision::GetTypeManager());

	ar_in.SetLoadingVersion(Vision::GetArchiveVersion());

	for (int i = 0; i < count; ++i)
	{
		IVObjectComponent * pDup = (IVObjectComponent *)types[i]->CreateInstance();

		pDup->Serialize(ar_in);
		pTo->AddComponent(pDup);
	}

	ar_in.Close();
}

/// Common validation failure logic
/// @param iParam [out] Validation argument, to be cast to a @b VisBeforeSceneExportedObject_cl pointer
/// @param message Failure format string
/// @param ... Format string arguments
void FailValidation (INT_PTR iParam, const char * message, ...)
{
	va_list args;

	va_start(args, message);

	((VisBeforeSceneExportedObject_cl *)iParam)->m_sErrMsg.FormatArgList(message, args);

	va_end(args);

	((VisBeforeSceneExportedObject_cl *)iParam)->m_bCancelExport = true;
}

/// Adds or removes an object ID from an array
/// @param pObject Object with unique ID to manage
/// @param id_array [out] The array to which the ID is added or from which it is removed
/// @param bRemove If true, remove the ID; otherwise, add it
void ManageObjectID (VisObject3D_cl * pObject, DynArray_cl<__int64> & id_array, bool bRemove)
{
	__int64 id = pObject->GetUniqueID();

	int index = id_array.GetElementPos(id);

	// If removing, empty the object's slot (if present).
	if (bRemove)
	{
		if (-1 == index) return;

		id_array.Remove(index);
	}

	// Otherwise, add the ID if it is not already in the array.
	else if (-1 == index) id_array[id_array.GetFreePos()] = id;
}

///
/// @param iID
/// @param iParam
/// @param pType
/// @param pbLinked [out]
/// @remark
void ManageTypeLink (int iID, INT_PTR iParam, VType * pType, bool * pbLinked)
{
	if (iID < VIS_MSG_EDITOR_CANLINK || iID > VIS_MSG_EDITOR_ONUNLINK) return;

	VShapeLink * pLink = (VShapeLink *)iParam;

	if (pLink->m_LinkInfo.GetUserData() != pType) return;

	if (VIS_MSG_EDITOR_CANLINK == iID)
	{
		VisObject3D_cl * pOther = (VisObject3D_cl *)pLink->m_pOtherObject;

		pLink->m_bResult = pOther && pOther->IsOfType(pType);
	}

	else if (pbLinked) *pbLinked = VIS_MSG_EDITOR_ONLINK == iID;
}

///
/// @param iID
/// @param iParam
/// @param pType
/// @param id [in-out]
/// @remark
void ManageTypeLinkID (int iID, INT_PTR iParam, VType * pType, __int64 & id)
{
	if (iID < VIS_MSG_EDITOR_CANLINK || iID > VIS_MSG_EDITOR_ONUNLINK) return;

	VShapeLink * pLink = (VShapeLink *)iParam;

	if (pLink->m_LinkInfo.GetUserData() != &id) return;

	VisObject3D_cl * pOther = (VisObject3D_cl *)pLink->m_pOtherObject;

	if (VIS_MSG_EDITOR_CANLINK == iID) pLink->m_bResult = pOther && (0 == id || pOther->GetUniqueID() == id) && pOther->IsOfType(pType);

	else
	{
		VASSERT(pOther);

		id = VIS_MSG_EDITOR_ONLINK == iID ? pOther->GetUniqueID() : 0;
	}
}

/// Loads elements from an array into a dropdown
/// @param iParam [out] Message argument, to be cast to a @b VStrList pointer
/// @param key Array key in master table
/// @param t Index of master table
/// @remark Elements are assumed to be strings
void PopulateDropdownFromLuaArray (lua_State * L, INT_PTR iParam, const char * key, int t)
{
	if (!lua_isnil(L, t))
	{
		lua_getfield(L, t, key);// ..., master_table, ..., array_or_nil

		if (lua_istable(L, -1))
		{
			for (int i = 1, size = Lua::GetN(L, -1); i <= size; ++i, lua_pop(L, 1))
			{
				lua_rawgeti(L, -1, i);	// ..., master_table, ..., array, entry

				((VStrList *)iParam)->AddUniqueString(Lua::S(L, -1));
			}
		}

		lua_pop(L, 1);	// ..., master_table, ...
	}
}

/// Loads keys from a table into a dropdown
/// @param iParam [out] Message argument, to be cast to a @b VStrList pointer
/// @param key Table key in master table
/// @param t Index of master table
/// @remark Keys are assumed to be strings
void PopulateDropdownFromLuaTableKeys (lua_State * L, INT_PTR iParam, const char * key, int t)
{
	if (!lua_isnil(L, t))
	{
		lua_getfield(L, t, key);// ..., master_table, ..., table_or_nil

		if (lua_istable(L, -1))
		{
			for (lua_pushnil(L); lua_next(L, -2) != 0; lua_pop(L, 1))
			{
				((VStrList *)iParam)->AddUniqueString(Lua::S(L, -2));
			}
		}

		lua_pop(L, 1);	// ..., master_table, ...
	}
}

/// Helper to push common first call arguments
/// @param name
/// @param pObject
/// @param bIsProxy
void PushFirstArgs (lua_State * L, void * key, const char * name, VisTypedEngineObject_cl * pObject, bool bIsProxy)
{
	VASSERT(key);

	lua_pushlightuserdata(L, key);	// ..., key

	// Add the string argument.
	name ? lua_pushstring(L, name) : lua_pushnil(L);// ..., key, name_or_nil

	// Push the object or its proxy.
	if (!pObject) lua_pushnil(L);	// ..., key, name_or_nil, nil

	else if (bIsProxy) LUA_PushObjectProxy(L, VScriptResourceManager::GetScriptComponent(pObject));	// ..., key, name_or_nil, proxy

	else lua_pushlightuserdata(L, pObject);	// ..., key, name_or_nil, pObject
}

///
/// @param pType
/// @param name
/// @param bZoneBased
void RegisterCollectionAndContext (lua_State * L, const VType * pType, const char * name, bool bZoneBased)
{
	EntityManager_cl::GetMe()->AddNewCollection(pType, name, bZoneBased);

	// Bind the type as context ID.
	if (!Vision::Editor.IsInEditor()) Lua_PCall(L, "game_objects_helpers.BindTypeAsContextID", 0, "su", name, pType);
}

/// Finds a substring in a separated value string
/// @param str Source string
/// @param substr [out] On success, substring #<i>which</i>
/// @param which Index of separated substring
/// @param separator Separator character, '.' by default
/// @return If true, substring was found
bool FindSubstring (const char * str, VString & substr, int which, char separator)
{
	VASSERT(which >= 0);

	for (int i = 0; ; ++i)
	{
		const char * sep = strchr(str, separator);

		if (i == which)
		{
			if (sep) substr.Left(str, sep - str);

			else substr = str;

			return true;
		}

		else if (!sep) break;

		else str = sep + 1;
	}

	return false;
}

/// @return If true, object has been committed
/// @remark Wrapper around EntityManager_cl::IsCommitted()
bool IsCommitted (VisTypedEngineObject_cl * pObject)
{
	return EntityManager_cl::GetMe()->IsCommitted(pObject);
}

/// Tests whether a flag is clear; if so, sets it
/// @param flag [in-out] Flag to test / set
/// @return If true, flag was clear
bool IsFlagClear_Flip (bool & bFlag)
{
	if (bFlag) return false;

	bFlag = true;

	return true;
}

/// Tests whether a flag is set; if so, clears it
/// @param flag [in-out] Flag to test / clear
/// @return If true, flag was set
bool IsFlagSet_Flip (bool & bFlag)
{
	if (!bFlag) return false;

	bFlag = false;

	return true;
}

/// Helper to split a string into two substrings
/// @param str Source string
/// @param prefix [out] On success, the substring before the first instance of the separator
/// @param rest [out] On success, the substring after the first instance of the separator
/// @param separator Separator character, '.' by default
/// @return If true, string could be broken up
bool SplitString (const char * str, VString & prefix, VString & rest, char separator)
{
	const char * sep = strchr(str, separator);

	if (NULL == sep) return false;

	rest = sep + 1;

	prefix.Left(str, sep - str);

	return true;
}

/// Helper to get a Lua function from a static key (binding it on the first use) and prepare for CallFromStack()
/// @param bHasBound [out]
/// @param name
int BindAndPushFuncRef (lua_State * L, bool & bHasBound, const char * name)
{
	lua_pushlightuserdata(L, &bHasBound);	// ..., key

	if (IsFirstInstance(bHasBound))
	{
		lua_pushvalue(L, -1);	// ..., key, key

		Lua::GetGlobal(L, name);// ..., key, key, call

		lua_rawset(L, LUA_REGISTRYINDEX);	// ..., key
	}

	lua_rawget(L, LUA_REGISTRYINDEX);	// ..., call

	return lua_gettop(L);
}

///
/// @param pObject
/// @param pBaseType
int CountComponents (const VisTypedEngineObject_cl * pObject, VType * pBaseType)
{
	return CountComponents(pObject->Components(), pBaseType);
}

///
/// @param comps
/// @param pBaseType
int CountComponents (const VObjectComponentCollection & comps, VType * pBaseType)
{
	VASSERT(!pBaseType || pBaseType->IsDerivedFrom(V_RUNTIME_CLASS(IVObjectComponent)));

	if (!pBaseType) pBaseType = V_RUNTIME_CLASS(IVObjectComponent);

	int count = 0;

	for (int i = 0; i < comps.Count(); ++i)
	{
		IVObjectComponent * pComp = comps.GetAt(i);

		if (pComp && pComp->IsOfType(pBaseType)) ++count;
	}

	return count;
}

/// Counts the number of separated values in a string
/// @param str Source string
/// @param separator Separator character, '.' by default
/// @return Number of substrings
int CountSubstrings (const char * str, char separator)
{
	int count = 0;

	for ( ; str; ++count)
	{
		const char * sep = strchr(str, separator);

		str = sep ? sep + 1 : NULL;
	}

	return count;
}

/// Common logic at the beginning of a versioned serialization
/// @param iLocalVersion Version number to save, or to compare against loaded value
/// @return Loaded version number (0xFF when saving)
char BeginVersionedSerialize (VArchive & ar, char iLocalVersion)
{
	char iReadVersion = char(~0);

	if (ar.IsLoading())
	{
		ar >> iReadVersion;

		VASSERT_MSG(iReadVersion <= iLocalVersion, "Invalid local version. Please re-export");
	}

	else ar << iLocalVersion;

	return iReadVersion;
}

/// Specialization of BeginVersionedSerialize() for components
char BeginComponentSerialize (IVObjectComponent * pComp, VArchive & ar, char iLocalVersion)
{
	return BeginVersionedSerialize(pComp, ar, iLocalVersion);
}

/// Specialization of BeginVersionedSerialize() for entities
char BeginEntitySerialize (VisBaseEntity_cl * pEntity, VArchive & ar, char iLocalVersion)
{
	return BeginVersionedSerialize(pEntity, ar, iLocalVersion);
}

/// Helper to get a native pointer, when it may be either raw or boxed
/// @param index Stack index of element
/// @return Pointer to object
VisTypedEngineObject_cl * NativePtr (lua_State * L, int index)
{
	if (lua_type(L, index) == LUA_TLIGHTUSERDATA) return (VisTypedEngineObject_cl *)lua_touserdata(L, index);

	return LUA_GetNativeObject(L, index);
}

/// @param what Type of object, one of the following: @b "ConvexVolume", @b "Entity", @b "LightSource", @b "Path", @b "StaticMeshInstance"
/// @param key Key of object to be found
/// @return Pointer to object, or @b NULL if absent
VisTypedEngineObject_cl * GetObjectByKey (const char * what, const char * key)
{
	VASSERT(what);
	VASSERT(key);

	VisTypedEngineObject_cl * pObject = NULL;

	#define SEARCH_OBJECT(type) if (strcmp(what, #type) == 0) return Vision::Game.Search##type##(key)

	SEARCH_OBJECT(ConvexVolume);
	else SEARCH_OBJECT(Entity);
	else SEARCH_OBJECT(LightSource);
	else SEARCH_OBJECT(Path);
	else SEARCH_OBJECT(StaticMeshInstance);
	else VASSERT_MSG(false, "Invalid search type");

	#undef SEARCH_OBJECT

	return pObject;
}

///
/// @param iParam
/// @param id
/// @param custom_message
VisPath_cl * EnsurePath (INT_PTR iParam, __int64 id, const char * custom_message)
{
	if (!id || !VisPath_cl::FindByUniqueID(id)) FailValidation(iParam, custom_message ? custom_message : "Path missing");

	return VisPath_cl::FindByUniqueID(id);
}

/// @param pObject
/// @param name
/// @param num
/// @return
const VStaticString<MAX_VARNAME_LEN + 1> & GetEnumValue (VisTypedEngineObject_cl * pObject, const char * name, int num)
{
	static VStaticString<MAX_VARNAME_LEN + 1> str;

	VisVariable_cl * pVar = pObject->GetVariable(name);

	VASSERT(pVar);
	VASSERT(VULPTYPE_ENUM == pVar->type);
	VASSERT(num >= 0 && num < pVar->GetEnumCount());

	pVar->GetEnumField(num, str);

	return str;
}
--]]