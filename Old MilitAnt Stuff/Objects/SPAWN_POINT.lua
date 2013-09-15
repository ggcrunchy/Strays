--- Spawn point from C++.

--[[
--
--
-- SpawnPoint.h
--
--
#ifndef _SPAWN_POINT_CL
#define _SPAWN_POINT_CL

#include "entitylinks.h"

// Forward references
struct EnemyTemplate;

class ActionLink_cl;
class ConditionLink_cl;
class Enemy_cl;
class NativeClassInfo;
class TimeoutComponent_cl;

/// An entity used to manage enemies
class SpawnPoint_cl : public VisBaseEntity_cl {
public:
	SpawnPoint_cl (void);

	VOVERRIDE void GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info);
	VOVERRIDE void InitFunction (void);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);
	VOVERRIDE void OnDeserializationCallback (void * pUserData);
	VOVERRIDE void ThinkFunction (void);

	VOVERRIDE VBool WantsDeserializationCallback (void) { return true; }

	V_DECLARE_SERIAL_DLLEXP(SpawnPoint_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(SpawnPoint_cl)

	void PushProxy (lua_State * L);

	static SpawnPoint_cl * Bind (Enemy_cl * enemy);

	/// Current spawn point state
	struct State {
		TimeoutComponent_cl * mDrowse;	///< @e DrowseDelay-based state
		TimeoutComponent_cl * mEmit;///< @e EmitDelay-based state
		TimeoutComponent_cl * mWait;///< @e WaitDelay-based state
		float mPenalty;	///< Emit penalty, normalized and resolved to difficulty level
		int mMaxActive;	///< Number of spawned enemies that may be active, resolved to difficulty level and evaluated
		int mMaxSpawns;	///< @e MaxSpawns, resolved to difficulty level
		int mNumActive;	///< Number of enemies currently active
		int mNumSpawns;	///< Number of spawns that have occurred
	};

	const State & GetState (void) const { return mState; }
	const VPListT<VisBaseEntity_cl> & GetRefEntities (void) const { return mRefEntities; }
	const VPListT<VisPath_cl> & GetRefPaths (void) const { return mRefPaths; }
	const VisEntityCollection_cl & GetEnemies (void) const { return mEnemies; }

private:
	enum {
		AwakeFlag,	///< Flag indicating whether this spawn point is awake
		DisabledFlag,	///< Flag indicating whether this spawn point is disabled
		DrowsyFlag,	///< Flag indicating that spawn point is drowsy
		WaitFlag,	///< Flag indicating that spawn point is waiting to reset
		_nFlagBits	///< How many flag bits were enumerated
	};

	/// Per-difficulty settings
	struct Settings {
		int DrowseDelay;///< Delay (ms) before a drowsy spawn point goes to sleep
		int EmitDelay;	///< Delay (ms) between enemy spawns
		int EmitPenalty;///< Delay (ms) extension for emits after a kill
		int WaitDelay;	///< Delay (ms) until reset when cleared and choosing to wait
		int ActiveAtOnce1;	///< Bound #1, for number of enemies that may be active at once
		int ActiveAtOnce2;	///< Bound #2, paired with @e ActiveAtOnce1
		int MaxSpawns;	///< Number of enemies that may be spawned before the spawn point is clear
	};

	void Alert (lua_State * L, const StrComp & what, INT_PTR iParam);
	void AlertAllRefs (const char * what, INT_PTR iParam = 0);
	void ApplyAll (void (Enemy_cl::*func)(void));
	void BindModel (void);
	void CleanUp (lua_State * L);
	void Commit (lua_State * L);
	void DefaultCase (int iID, INT_PTR iParamA, INT_PTR iParamB);
	void EmitEnemy (void);
	void EnumAlerts (const StrComp & what, INT_PTR iParam);
	void EnumProperties (const StrComp & what, INT_PTR iParam);
	void EnumVarieties (lua_State * L, INT_PTR iParam);
	void GetDrowsy (void);
	void FindModelEntry (lua_State * L);
	void MemArchive (VArchive & ar);
	void NewInstance (lua_State * L, BOOL bFirst);
	void OnEnable (bool bManual, bool bEnable);
	void PostClear (lua_State * L);
	void PostKill (lua_State * L);
	void PostSleep (lua_State * L);
	void PostSpawn (lua_State * L);
	void PostWake (lua_State * L);
	void PublicAlert (const StrComp & what, INT_PTR iParam);
	void ReconstructVars (void);
	void RemoveAll (bool bKill, bool bRemove = false);
	void RemoveEnemy (Enemy_cl * pEnemy, bool bKill);
	void Reset (void);
	void SendAlertToEnemy (INT_PTR iParamA, INT_PTR iParamB);
	void SerializeSettings (VArchive & ar, Settings & settings);
	void Sleep (void);
	void Standby (bool bEnter);
	void Trigger (VisTriggerSourceComponent_cl * pSource, VisTriggerTargetComponent_cl * pTarget);
	void Validate (INT_PTR iParam);
	void Wake (void);

	bool HasEnemy (void) { return sEnemies >= 0 && HasModel(); }
	bool IsClear (void) { return 0 == mState.mNumActive && mState.mNumSpawns == mState.mMaxSpawns; }
	bool IsFull (void) { return mState.mNumActive == mState.mMaxActive || mState.mNumSpawns == mState.mMaxSpawns; }

	static NativeClassInfo sNativeClassInfo;///< Info for class proxy
	static SpawnPoint_cl * sBindTo;	///< Spawn point used to bind new enemies
	static int sEnemies;///< Enemies config table reference

	// vForge variables
	VString Variety;///< AI variety

	BOOL AwakeIfEnabled;///< If true, awake and enabled are the same for this spawn point (and it disregards touches)
	BOOL EnabledWhenZoneEntered;///< If true, the spawn point is enabled when the zone is entered
	BOOL KillActive;///< If true, kill active enemies when turned off
	BOOL LeaveByBoxToo;	///< If true, a trigger box that would trip @b AddTouch via @b On*Enter (@b * = either @b Object or @b Camera) is configured to also trip @b RemoveTouch via @b On*Leave
	BOOL RemoveOnDisable;	///< If true, the spawn point should be removed from the scene if it becomes disabled

	int OnClearOp;	///< Operation to execute when the spawn point is cleared
	int OnSleepOp;	///< Operation to execute when the spawn point is put to sleep

	union {
		struct {
			Settings Easy;	///< Easy difficulty settings
			BOOL EasySameAsMedium;	///< If true, @e Medium is referenced instead of @e Easy
			Settings Medium;///< Medium difficulty settings
			BOOL HardSameAsMedium;	///< If true, @e Medium is referenced instead of @e Hard
			Settings Hard;	///< Hard difficulty settings
			BOOL ExtremeSameAsHard;	///< If true, @e Hard is referenced instead of @e Extreme
			Settings Extreme;	///< Extreme difficulty settings
		};

	// Implementation
		State mState;	///< Various spawn point state
	};

	VPListT<VisBaseEntity_cl> mRefEntities;	///< Reference entities established by links
	VPListT<VisPath_cl> mRefPaths;	///< Reference paths established by links
	SerialDynArray_cl<__int64> mEntityUniqueIds;///< ID's used to serialize / deserialize entity links
	SerialDynArray_cl<__int64> mPathUniqueIds;	///< ID's used to serialize / deserialize path links
	VSmartPtr<VisTriggerTargetComponent_cl> mAddOneTouch;	///< Target to tell this spawn point something has begun touching it
	VSmartPtr<VisTriggerTargetComponent_cl> mDisable;	///< Target to disable this spawn point
	VSmartPtr<VisTriggerTargetComponent_cl> mEnable;///< Target to enable this spawn point
	VSmartPtr<VisTriggerTargetComponent_cl> mImpulse;	///< Target to tell this spawn point something began and then immediately stopped touching it
	VSmartPtr<VisTriggerTargetComponent_cl> mRemoveOneTouch;///< Target to tell this spawn point something has stopped touching it
	VSmartPtr<ActionLink_cl> mOnClear;	///< Link to @e On(Clear) actions
	VSmartPtr<ActionLink_cl> mOnDisable;///< Link to @e On(Disable) actions
	VSmartPtr<ActionLink_cl> mOnKill;	///< Link to @e On(Kill) actions
	VSmartPtr<ActionLink_cl> mOnReset;	///< Link to @e On(Reset) actions
	VSmartPtr<ActionLink_cl> mOnSleep;	///< Link to @e On(Sleep) actions
	VSmartPtr<ActionLink_cl> mOnSpawn;	///< Link to @e On(Spawn) actions
	VSmartPtr<ActionLink_cl> mOnWake;	///< Link to @e On(Wake) actions
	VSmartPtr<ConditionLink_cl> mIsEnabledWhenZoneEntered;	///< Link for condition: should the spawn point be enabled when the zone is entered?
	VSmartPtr<EnemyTemplate> mEnemyInfo;///< Common enemy initialization info
	VBitfield mFlags;	///< State flags
	VisEntityCollection_cl mEnemies;///< Enemies currently spawned
	TriggerBoxPair mTouchPair;	///< @b AddTouch / @b RemoveTouch management
	int mPenaltyCount;	///< Number of penalties to impose
	int mRefProxy;	///< Reference to spawn point proxy
	int mTouchCount;///< Number of objects touching the spawn point
};

#endif
--]]

--[[
--
--
-- SpawnPoint.cpp
--
--
#include "stdafx.h"
#include "Game.h"
#include "enemy.h"
#include "actionlink.h"
#include "conditionlink.h"
#include "spawnpoint.h"
#include "timeoutcomponent.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>
#include "Lua_/Arg.h"

/// Constructor
SpawnPoint_cl::SpawnPoint_cl (void) : mEnemies(16, 256), mPenaltyCount(0), mRefProxy(LUA_NOREF), mTouchCount(0)
{
	mEntityUniqueIds.SetDefaultValue(0);
	mPathUniqueIds.SetDefaultValue(0);
}

/// Hides @b Easy, @b Hard, and @b Extreme settings groups when those shadow @b Medium, @b Medium, or @b Hard, respectively
void SpawnPoint_cl::GetVariableAttributes (VisVariable_cl * pVar, VVariableAttributeInfo & info)
{
	DO_ARRAY(struct {
		const char * mPrefix;	///< Prefix to match
		BOOL mSame;	///< Given a match, bool member used to indicate sameness
	}, names, i,
		{ "Easy.", EasySameAsMedium },
		{ "Hard.", HardSameAsMedium },
		{ "Extreme.", ExtremeSameAsHard }
	) {
		if (!VStringHelper::StartsWith(pVar->GetName(), names[i].mPrefix)) continue;

		info.m_bHidden = names[i].mSame != FALSE;

		return;
	}
}

/// Initialization
void SpawnPoint_cl::InitFunction (void)
{
	VisBaseEntity_cl::InitFunction();

	SetThinkFunctionStatus(FALSE);

	if (!Vision::Editor.IsInEditor())
	{
		SetVisibleBitmask(0);

		ReconstructVars();
	}

	static bool sRegistered;

	OnNewInstance(this, sRegistered);
}

/// Message handler
void SpawnPoint_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	if (IsRemoved() && (VIS_MSG_TRIGGER == iID || ID_OBJECT_ALERT)) return;

	lua_State * L = VScriptRM()->GetMasterState();

	switch (iID)
	{
	// Trigger: iParamA = VisTriggerSourceComponent_cl *, iParamB = VisTriggerTargetComponent_cl *
	case VIS_MSG_TRIGGER:
		Trigger((VisTriggerSourceComponent_cl *)iParamA, (VisTriggerTargetComponent_cl *)iParamB);

		break;

	// New Instance: iParamA = BOOL
	case ID_OBJECT_NEW_INSTANCE:
		NewInstance(L, iParamA);

		break;

	// Commit
	case ID_OBJECT_COMMIT:
		Commit(L);

		break;

	// Clean up
	case ID_OBJECT_CLEANUP:
		CleanUp(L);

		break;

	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	case ID_OBJECT_ALERT:
		Alert(L, iParamA, iParamB);

		break;

	// Public alert: iParamA = const char * or NULL, iParamB = AlertPacket *
	case ID_OBJECT_PUBLIC_ALERT:
		PublicAlert(iParamA, iParamB);

		break;

	// Memory state archive: iParamA = VArchive *
	case ID_OBJECT_MEMORY_STATE_ARCHIVE:
		MemArchive(*(VArchive *)iParamA);

		break;

	// Validate export: iParamA = VisBeforeSceneExportedObject_cl *
	case ID_OBJECT_VALIDATE_EXPORT:
		Validate(iParamA);

		break;

	// Other cases
	default:
		// Property Changed: iParamA = const char *, iParamB = const char *
		if (VIS_MSG_EDITOR_PROPERTYCHANGED == iID && StrComp(iParamA) == "ModelFile") Vision::Editor.SetVariableInEditor(this, "Variety", "Normal", true, false);

		// Get Standard Values: iParamA = const char *, iParamB = VStrList *
		else if (VIS_MSG_EDITOR_GETSTANDARDVALUES == iID)
		{
			StrComp what(iParamA);

			if (what == "ai_variety" && HasEnemy()) EnumVarieties(L, iParamB);
			else if (VStringHelper::StartsWith(what, "enum_alerts:")) EnumAlerts(what, iParamB);
			else if (VStringHelper::StartsWith(what, "enum_properties:")) EnumProperties(what, iParamB);
		}

		// Anything else
		else DefaultCase(iID, iParamA, iParamB);

		VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
	}
}

/// Resolves ref entity and path ID's and performs initialization
void SpawnPoint_cl::OnDeserializationCallback (void * pUserData)
{
	ResolveObjectIDs(mRefEntities, mEntityUniqueIds);
	ResolveObjectIDs(mRefPaths, mPathUniqueIds);

	InitFunction();
}

/// Updates reset, drowsy, and reset wait timers, handling any timeout logic
void SpawnPoint_cl::ThinkFunction (void)
{
	VASSERT(IsCommitted(this) && !mFlags.IsBitSet(DisabledFlag));

	lua_State * L = VScriptRM()->GetMasterState();

	float dt = Vision::Timer.GetTimeDifference();

	bool bFellAsleep = false;

	// If the spawn point is waiting for a reset and the delay times out, perform reset
	// logic. Any excess time is available to be accumulated by the emit timer.
	if (mFlags.IsBitSet(WaitFlag))
	{
		VASSERT(0 == mState.mNumActive);
		VASSERT(!mFlags.IsBitSet(DrowsyFlag));

		if (mState.mWait->UpdateCheckAndGetExcess(dt))
		{
			mFlags.RemoveBit(WaitFlag);

			SendTriggerMessage(this, mEnable);
		}
	}

	// Otherwise, if the spawn point is drowsy and the delay times out, it is ready to fall
	// asleep. Any time that elapsed before the timeout is available to be accumulated by
	// the emit timer; emit timeouts that occured in this interval are first processed.
	else bFellAsleep = mFlags.IsBitSet(DrowsyFlag) && mState.mDrowse->UpdateCheckAndGetShortage(dt);

	// If the spawn point is active, emit as many enemies as possible in the time slice,
	// stopping if the "active at once" count reaches full capacity.
	bool bActive = mFlags.IsBitSet(AwakeFlag) && !mFlags.IsBitSet(WaitFlag);

	if (bActive)
	{
		mState.mEmit->Update(dt - mState.mPenalty * mPenaltyCount);

		while (!IsFull() && mState.mEmit->CheckForTimeout()) EmitEnemy();
	}

	// Now that any penalties were imposed, reset the count.
	mPenaltyCount = 0;

	// Reset the emit timer if the spawn point deactivated or reached full capacity.
	if (!bActive || IsFull()) mState.mEmit->Reset();

	// Now that any emits are done, put the spawn point to sleep if was ready above.
	if (bFellAsleep) Sleep();
}

/// Serializes difficulty setting-based data
void SpawnPoint_cl::SerializeSettings (VArchive & ar, Settings & settings)
{
	if (ar.IsLoading())
	{
		ar >> settings.DrowseDelay;
		ar >> settings.EmitDelay;
		ar >> settings.WaitDelay;
		ar >> settings.ActiveAtOnce1;
		ar >> settings.ActiveAtOnce2;
		ar >> settings.MaxSpawns;
		ar >> settings.EmitPenalty;
	}

	else
	{
		ar << settings.DrowseDelay;
		ar << settings.EmitDelay;
		ar << settings.WaitDelay;
		ar << settings.ActiveAtOnce1;
		ar << settings.ActiveAtOnce2;
		ar << settings.MaxSpawns;

		/* VERSION 6 */
		ar << settings.EmitPenalty;
	}
}

/// Serialization
void SpawnPoint_cl::Serialize (VArchive & ar)
{
	Vision::Error.SystemMessage("HAI");
	const char VERSION = 8;

	char iReadVersion = BeginEntitySerialize(this, ar, VERSION);

	if (ar.IsLoading())
	{
		VASSERT_MSG(iReadVersion >= 6, "Obsolete spawn point version: please re-export");

		ar >> mEntityUniqueIds;
		ar >> mPathUniqueIds;
		ar >> KillActive;
		ar >> LeaveByBoxToo;
		ar >> AwakeIfEnabled;
		ar >> OnClearOp;
		ar >> OnSleepOp;
		ar >> Variety;
		ar >> EasySameAsMedium;
		ar >> HardSameAsMedium;
		ar >> ExtremeSameAsHard;

		if (iReadVersion >= 7) ar >> RemoveOnDisable;
		if (iReadVersion >= 8) ar >> EnabledWhenZoneEntered;
	}

	else
	{
		/* VERSION 1 */
		ar << mEntityUniqueIds;
		ar << mPathUniqueIds;
		ar << KillActive;
		ar << LeaveByBoxToo;
		ar << AwakeIfEnabled;
		ar << OnClearOp;
		ar << OnSleepOp;

		/* VERSION 2 */
		ar << Variety;

		/* VERSION 4 */
		ar << EasySameAsMedium;
		ar << HardSameAsMedium;

		/* VERSION 5 */
		ar << ExtremeSameAsHard;

		/* VERSION 7 */
		ar << RemoveOnDisable;

		/* VERSION 8 */
		ar << EnabledWhenZoneEntered;
	}

	/* VERSION 4: Medium / Easy reordered to retain some early settings */
	SerializeSettings(ar, Medium);
	SerializeSettings(ar, Easy);
	SerializeSettings(ar, Hard);

	/* VERSION 5 */
	SerializeSettings(ar, Extreme);
	Vision::Error.SystemMessage("BYE");
}

/// Pushes the spawn point's proxy on the stack
void SpawnPoint_cl::PushProxy (lua_State * L)
{
	if (mRefProxy >= 0) lua_getref(L, mRefProxy);	// ..., proxy

	else
	{
		LUA_CreateObjectProxy(L, this);	// ..., proxy

		lua_pushvalue(L, -1);	// ..., proxy, proxy

		mRefProxy = lua_ref(L, true);	// ..., proxy
	}
}

/// Converts various vForge variables into their run-time form
/// @remark These occupy the same union, thus some vForge variables will become invalid
void SpawnPoint_cl::ReconstructVars (void)
{
	// Add a singleton to cache the difficulty after scene loading.
	static struct : public IVisCallbackHandler_cl {
		void OnHandleCallback (IVisCallbackDataObject_cl * pData)
		{
			if (&Vision::Callbacks.OnAfterSceneLoaded == pData->m_pSender) Sync();

			else
			{
				Vision::Callbacks.OnAfterSceneLoaded -= this;
				Vision::Callbacks.OnEngineDeInit -= this;
			}
		}

		void Sync (void)
		{
			mValue = Game_cl::GetMe()->GetControlInt("Difficulty");
		}

		int mValue;	///< Current value
		bool mAdded;///< One-time add flag
	} sDifficulty;

	// On the first instance, force an update, since the scene has already been loaded.
	if (IsFirstInstance(sDifficulty.mAdded))
	{
		Vision::Callbacks.OnAfterSceneLoaded += sDifficulty;
		Vision::Callbacks.OnEngineDeInit += sDifficulty;

		sDifficulty.Sync();
	}

	// Choose the difficulty setting, correcting the index for C++. Start with the global
	// index and advance it by the current setting's delta, stopping when said delta is 0.
	struct {
		Settings & mChoice;	///< Possible setting to use
		int mDelta;	///< Index delta
	} settings[] = {
		{ Easy, EasySameAsMedium ? +1 : 0 },
		{ Medium, 0 },
		{ Hard, HardSameAsMedium ? -1 : 0 },
		{ Extreme, ExtremeSameAsHard ? -1 : 0 }
	};

	VASSERT(sDifficulty.mValue >= 1 && sDifficulty.mValue <= ArrayN(settings));

	int index = sDifficulty.mValue - 1;

	while (settings[index].mDelta != 0) index += settings[index].mDelta;

	// Make a stack copy of the chosen difficulty setting, so that the run-time part of the
	// union is safe to assign.
	Settings choice = settings[index].mChoice;

	// Reconstruct delays in fractional seconds form.
	DO_ARRAY(struct {
		int mRaw;	///< Original variable
		TimeoutComponent_cl *& mVar;///< Timeout variable
	}, delays, i,
		{ choice.DrowseDelay, mState.mDrowse },
		{ choice.EmitDelay, mState.mEmit },
		{ choice.WaitDelay, mState.mWait }
	) {
		delays[i].mVar = new TimeoutComponent_cl(float(delays[i].mRaw) / 1000, VIS_OBJECTCOMPONENTFLAG_NOSERIALIZE);

		AddComponent(delays[i].mVar);
	}

	// Given the bounds, compute a random ranged active amount.
	int num1 = choice.ActiveAtOnce1;
	int num2 = choice.ActiveAtOnce2;

	VASSERT(num1 >= 0 && num2 >= 0);

	if (0 == num1) num1 = num2;
	if (0 == num2) num2 = num1;

	mState.mMaxActive = __min(num1, num2) + (num1 != num2 ? Vision::Game.GetRand() % abs(num1 - num2) : 0);

	// Assign the max spawn count and limit the active count against it.
	mState.mMaxSpawns = choice.MaxSpawns;

	VASSERT(mState.mMaxActive > 0 || 0 == mState.mMaxSpawns);

	if (mState.mMaxSpawns != -1 && mState.mMaxActive > mState.mMaxSpawns) mState.mMaxActive = mState.mMaxSpawns;

	// Zero out counts.
	mState.mNumActive = 0;
	mState.mNumSpawns = 0;
}

/// If the spawn point is awake, invokes any @e On(Sleep) action on it and puts it to sleep, performing the behavior requested
void SpawnPoint_cl::Sleep (void)
{
	mFlags.RemoveBit(DrowsyFlag);

	if (IsBitSet_Flip(mFlags, AwakeFlag)) mOnSleep->Invoke(OnSleepOp);
}

/// @e On(Sleep) follow-up logic
void SpawnPoint_cl::PostSleep (lua_State * L)
{
	// Do the requested sleep op.
	const VStaticString<MAX_VARNAME_LEN + 1> & choice = GetEnumValue(this, "OnSleepOp", OnSleepOp);

	if (choice == "GoDormant") ApplyAll(&Enemy_cl::Scurry);

	else if (choice == "Reset") Reset();

	else VASSERT_MSG(false, "SpawnPoint_cl: Invalid sleep choice");

	// Alert all reference entities.
	AlertAllRefs("parent_fell_asleep");
}

/// If the spawn point is asleep, wakes it up and invokes any @e On(Wake) action on it
void SpawnPoint_cl::Wake (void)
{
	mFlags.RemoveBit(DrowsyFlag);

	if (IsBitClear_Flip(mFlags, AwakeFlag))
	{
		mState.mEmit->Reset();

		mOnWake->Invoke();
	}
}

/// @e On(Wake) follow-up logic
void SpawnPoint_cl::PostWake (lua_State *)
{
	// Alert all reference entities.
	AlertAllRefs("parent_woke_up");
}

/* Bindings */

/// Pushes the spawn point's AI variety string on the stack
static int GetVarietyB (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(SpawnPoint_cl *, sp);

	VString variety;

	SendAlert(sp, "get_variety", &variety);

	lua_pushstring(L, variety);

	return 1;
}

// Helper to find a ref element
template<typename T> int FindFirstRef (lua_State * L, const VPListT<T> & rlist)
{
	for (int i = 0; i < rlist.GetLength(); ++i)
	{
		T * pRef = rlist.Get(i);

		if (pRef)
		{
			LUA_CreateObjectProxy(L, pRef);	// sp, ref_object

			return 1;
		}
	}

	lua_pushnil(L);	// sp, nil

	return 1;
}

/// @remark Pointer to entity or @b nil is left on the stack
static int GetFirstRefEntityB (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(SpawnPoint_cl *, sp);

	return FindFirstRef(L, sp->GetRefEntities());
}

/// @remark Pointer to entity or @b nil is left on the stack
static int GetFirstRefPathB (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(SpawnPoint_cl *, sp);

	return FindFirstRef(L, sp->GetRefPaths());
}

// Helper to add ref elements during iteration
template<typename T> int PushRefProxy (lua_State * L, const VPListT<T> & rlist)
{
	int index = Lua::sI(L, 2);

	if (index >= rlist.GetLength()) return 0;

	lua_pushinteger(L, index + 1);	// sp, index, index + 1

	T * ref = rlist.Get(index);

	VASSERT(ref);

	LUA_CreateObjectProxy(L, ref);	// sp, index, index + 1, ref_object

	return 2;
}

/// Helper to iterate entities
static int AuxRefEntitiesIter (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(SpawnPoint_cl *, sp);

	return PushRefProxy(L, sp->GetRefEntities());
}

/// Helper to iterate paths
static int AuxRefPathsIter (lua_State * L)
{
	DECLARE_ARGS_OK;
	GET_OBJECT(SpawnPoint_cl *, sp);

	return PushRefProxy(L, sp->GetRefPaths());
}

/// Iterator factory for @b AuxRef* bindings
/// @remark Index and pointer are left on the stack at each iteration
template<lua_CFunction F> static int RefB (lua_State * L)
{
	lua_settop(L, 1);	// sp
	lua_pushcfunction(L, F);// sp, AuxRef
	lua_insert(L, 1);	// AuxRef, sp
	lua_pushinteger(L, 0);	// AuxRef, sp, 0

	return 3;
}

/* SpawnPoint_cl proxy methods */
static const luaL_Reg sMethods[] = 
{
	{ "GetFirstRefEntity", GetFirstRefEntityB },
	{ "GetFirstRefPath", GetFirstRefPathB },
	{ "GetVariety", GetVarietyB },
	{ "RefEntities", RefB<AuxRefEntitiesIter> },
	{ "RefPaths", RefB<AuxRefPathsIter> },
	{ 0, 0 }
};

NativeClassInfo SpawnPoint_cl::sNativeClassInfo =
{
	"SpawnPoint_cl", &VisBaseEntity_info, sMethods
};

/// Helper for repeated int variable definitions
#define VAR_INT(name, desc, def) DEFINE_VAR_INT(SpawnPoint_cl, name, desc, def, 0, NULL)

/// Settings variable block definitions
#define SETTINGS(prefix)																									\
	/* Capacity */																											\
	VAR_INT(prefix##.ActiveAtOnce1, "How many enemies may be active at once? (bounds #1)\n0 = same as #2", "1");			\
	VAR_INT(prefix##.ActiveAtOnce2, "How many enemies may be active at once? (bounds #2)\n0 = same as #1", "0");			\
	VAR_INT(prefix##.MaxSpawns, "How many enemies may be spawned, total?\n0 = (permanently) disabled, -1 = unlimited", "1");\
																															\
	/* Delays */																											\
	VAR_INT(prefix##.DrowseDelay, "Time (in milliseconds) until a drowsy spawn point falls asleep", "5000");				\
	VAR_INT(prefix##.EmitDelay, "Time (in milliseconds) between enemy spawns", "500");										\
	VAR_INT(prefix##.EmitPenalty, "Penalty (in milliseconds) on emitting enemies after a kill", "500");						\
	VAR_INT(prefix##.WaitDelay, "Time (in milliseconds) to wait for reset after being cleared", "30000");					

/// Settings variable block definitions, with sameness bool variable
#define SETTINGS_EX(prefix, prev_prefix)																							\
	DEFINE_VAR_BOOL(SpawnPoint_cl, prefix##SameAs##prev_prefix, "Reuse values from " #prev_prefix " difficulty", "TRUE", 0, NULL);	\
																																	\
	SETTINGS(prefix);

/* SpawnPoint_cl variables */
V_IMPLEMENT_SERIAL( SpawnPoint_cl, VisBaseEntity_cl /*parent class*/ , 0, &gGameModule );

START_VAR_TABLE(SpawnPoint_cl, VisBaseEntity_cl, "", VVARIABLELIST_FLAGS_NONE, "defaultBox")

	/* AI variety */
	DEFINE_VAR_VSTRING(SpawnPoint_cl, Variety, "Variety of AI (if more than one is available) for this model", "Normal", 0, 0, "Dropdown(ai_variety)");

	/* Per-difficulty settings */
	SETTINGS_EX(Easy, Medium)
	SETTINGS(Medium)
	SETTINGS_EX(Hard, Medium)
	SETTINGS_EX(Extreme, Hard)

	/* On(Clear) */
	DEFINE_VAR_ENUM(SpawnPoint_cl, OnClearOp, "Action on being cleared", "Disable", "Disable,Wait", 0, 0);

	/* On(Sleep) */
	DEFINE_VAR_ENUM(SpawnPoint_cl, OnSleepOp, "Action on being put to sleep", "GoDormant", "GoDormant,Reset", 0, 0);

	/* On(Enable) */
	DEFINE_VAR_BOOL(SpawnPoint_cl, AwakeIfEnabled, "Is the spawn point always awake if enabled (and asleep if disabled)?", "FALSE", 0, 0);

	/* On(Disable) */
	DEFINE_VAR_BOOL(SpawnPoint_cl, KillActive, "Should active enemies be killed if the spawn point turns off?", "FALSE", 0, 0);
	DEFINE_VAR_BOOL(SpawnPoint_cl, RemoveOnDisable, "Should the spawn point be permanently removed if it gets disabled?", "FALSE", 0, 0);

	/* Convenience */
	DEFINE_VAR_BOOL(SpawnPoint_cl, EnabledWhenZoneEntered, "Is spawn point enabled when you enter the zone?", "TRUE", 0, 0);
	DEFINE_VAR_BOOL(SpawnPoint_cl, LeaveByBoxToo, "If an object begins touching this spawn point by entering a trigger box, should it stop touching it when it leaves that box?", "FALSE", 0, 0);

END_VAR_TABLE
--]]

--[[
--
--
-- SpawnPoint_Enemy.cpp
--
--
#include "stdafx.h"
#include "actionlink.h"
#include "enemy.h"
#include "spawnpoint.h"
#include "timeoutcomponent.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>
#include "Lua_/Helpers.h"

/* Static bindings */
SpawnPoint_cl * SpawnPoint_cl::sBindTo = NULL;

/// Applies a method across all enemies
/// @param func Enemy member function
void SpawnPoint_cl::ApplyAll (void (Enemy_cl::*func)(void))
{
	for (unsigned i = 0; i < mEnemies.GetNumEntries(); ++i)
	{
		Enemy_cl * pEnemy = (Enemy_cl *)mEnemies.GetDataPtr()[i];

		if (pEnemy) (pEnemy->*func)();
	}
}

/// Binds the enemy to the current spawn point
/// @param enemy Enemy to bind
/// @return Current spawn point, for enemy to bind on its own
SpawnPoint_cl * SpawnPoint_cl::Bind (Enemy_cl * enemy)
{
	VASSERT(enemy);
	VASSERT_MSG(sBindTo, "Attempt to bind an enemy outside spawn point control");

	sBindTo->mEnemies.AppendEntry(enemy);

	return sBindTo;
}

/// Given the current model, binds it to any appropriate enemy configuration
/// @remark Any previous binding is removed
void SpawnPoint_cl::BindModel (void)
{
	mEnemyInfo = NULL;

	if (HasEnemy())
	{
		lua_State * L = VScriptRM()->GetMasterState();

		FindModelEntry(L);	// ..., entry

		if (!lua_isnil(L, -1)) mEnemyInfo = Enemy_cl::InitTemplate(L, Variety);

		lua_pop(L, 1);	// ...
	}
}

/// Logic for instantiating an Enemy_cl, binding its script state, and invoking any @e On(Spawn) action on it
void SpawnPoint_cl::EmitEnemy (void)
{
	VASSERT(mState.mNumActive < mState.mMaxActive);
	VASSERT(mState.mNumSpawns != mState.mMaxSpawns);

	if (!mEnemyInfo) return;

	// Set up binding context and generate an enemy within it, tearing it down afterward.
	sBindTo = this;

	Enemy_cl * enemy = (Enemy_cl *)Vision::Game.CreateEntity("Enemy_cl", GetPosition(), GetModel()->GetFilename());

	enemy->SetAmbientColor( GetAmbientColor() );
	enemy->SetEntityKey("enemy");

	sBindTo = NULL;

	VASSERT_MSG(mEnemies.GetIndexOf(enemy) != -1, "Emitted enemy was not bound");

	// Assign enemy properties.
	VScriptResourceManager * sm = VScriptRM();

	enemy->Set(*mEnemyInfo);

	IVScriptInstance * scriptInstance = sm->CreateScriptInstanceFromFile(mEnemyInfo->mFile);

	VASSERT(scriptInstance);

	sm->SetScriptInstance(enemy, scriptInstance);

	// Invoke 'On(Spawn)' action.
	mOnSpawn->Invoke(enemy, true);
}

/// @e On(Spawn) follow-up logic
void SpawnPoint_cl::PostSpawn (lua_State *)
{
	++mState.mNumActive;

	// Forgo counting the spawn if spawns are unlimited.
	if (mState.mMaxSpawns > 0) ++mState.mNumSpawns;
}

/// Given this entity's model, finds the corresponding enemy's entry in the config list
/// @remark The entry (or @b nil) is left on the stack
void SpawnPoint_cl::FindModelEntry (lua_State * L)
{
	lua_getref(L, sEnemies);// ..., enemies
	lua_getfield(L, -1, "FindEnemy");	// ..., enemies, enemies.FindEnemy
	lua_insert(L, -2);	// ..., enemies.FindEnemy, enemies
	lua_pushstring(L, GetModel()->GetFilename());	// ..., enemies.FindEnemy, enemies, model
	lua_PCALL(L, 2, 1, 0);	// ..., entry
}

/// Removes all active enemies produced by this spawn point from the scene
/// @param bKill If true, enemies will die (with usual behavior and side effects) rather than just be retired
/// @param bRemove If true, enemies should also mark themselves as removed
/// @remark The heavy lifting is done by the enemy itself
void SpawnPoint_cl::RemoveAll (bool bKill, bool bRemove)
{
	if (bRemove) ApplyAll(&Enemy_cl::Remove);

	ApplyAll(bKill ? &Enemy_cl::Die : &Enemy_cl::Retire);

	VASSERT(0 == mState.mNumActive);
}

/// Spawn point-side logic for removing one of its enemies from the scene
/// @param pEnemy Enemy to remove
/// @param bKill If true, the enemy died and the @e On(Kill) action is invoked on it
void SpawnPoint_cl::RemoveEnemy (Enemy_cl * pEnemy, bool bKill)
{
	VASSERT(mState.mNumActive > 0);
	VASSERT(mState.mNumSpawns > 0);
	VASSERT_MSG(!sBindTo, "Cannot remove enemy while attempting to add another");

	// Count the removal and invoke 'On(Kill)' action.
	--mState.mNumActive;

	if (bKill) mOnKill->Invoke(pEnemy, true);

	// Remove the enemy from the list.
	int index = mEnemies.GetIndexOf(pEnemy);

	VASSERT_MSG(index != -1, "Attempt to remove enemy not bound to the spawn point");

	mEnemies.FlagForRemoval(index);

	// If this was a kill that cleared the spawn point, invoke 'On(Clear)' action. This is
	// ignored if the kill resulted from disabling the spawn point.
	if (bKill && !mFlags.IsBitSet(DisabledFlag) && IsClear()) mOnClear->Invoke(OnClearOp);
}

/// @e On(Clear) follow-up logic
void SpawnPoint_cl::PostClear (lua_State * L)
{
	// Do the requested clear op.
	const VStaticString<MAX_VARNAME_LEN + 1> & choice = GetEnumValue(this, "OnClearOp", OnClearOp);

	if (choice == "Disable") Trigger(NULL, mDisable);

	else if (choice == "Wait")
	{
		mFlags.SetBit(WaitFlag);

		mState.mWait->Reset();
	}

	else VASSERT_MSG(false, "SpawnPoint_cl: Invalid clear choice");
}

/// @e On(Kill) follow-up logic
void SpawnPoint_cl::PostKill (lua_State *)
{
	++mPenaltyCount;
}

/// Accumulator used by enemy search
struct EnemySearch {
	Enemy_cl * mEnemy;	///< Current best choice
	unsigned mTarget;	///< Target index used in some searches
	bool mStop;	///< If true, stop iterating
};

// Helper to find an enemy meeting some conditions
static unsigned FindEnemy (VisEntityCollection_cl & enemies, void (*func)(Enemy_cl *, int, EnemySearch &), EnemySearch & search)
{
	unsigned int index = 0;

	for (unsigned i = 0; i < enemies.GetNumEntries() && !search.mStop; ++i)
	{
		VisBaseEntity_cl * pEnemy = enemies.GetDataPtr()[i];

		if (pEnemy) func((Enemy_cl *)pEnemy, index++, search);
	}

	return index;
}

// Enemy lookup by target index
static void ByIndex (Enemy_cl * pEnemy, int index, EnemySearch & search)
{
	search.mStop = index == search.mTarget;

	if (search.mStop) search.mEnemy = pEnemy;
}

// Enemy lookup by minimum HP
static void ByMinHP (Enemy_cl * pEnemy, int, EnemySearch & search)
{
	if (!search.mEnemy || pEnemy->GetHPDiff(search.mEnemy) < 0) search.mEnemy = pEnemy;
}

// Enemy lookup by maximum HP
static void ByMaxHP (Enemy_cl * pEnemy, int, EnemySearch & search)
{
	if (!search.mEnemy || pEnemy->GetHPDiff(search.mEnemy) > 0) search.mEnemy = pEnemy;
}

/// Public alert handler for enemies
/// @param iParamA Alert message
/// @param iParamB Alert packet
void SpawnPoint_cl::SendAlertToEnemy (INT_PTR iParamA, INT_PTR iParamB)
{
	if (mEnemies.IsEmpty()) return;

	AlertPacket * ap = (AlertPacket *)iParamB;

	VASSERT(AlertPacket::eString == ap->mPayloadType);

	EnemySearch search = { 0 };

	/* First or indexed enemy */
	if (ap->StartsWith("enemy:") || ap->StartsWith("enemy", search.mTarget)) FindEnemy(mEnemies, ByIndex, search);

	/* Random enemy */
	else if (ap->StartsWith("enemy?:"))
	{
		// Choose a slot and find the enemy there. Return the number of used slots found
		// during the search, which will be the total in the collection on failure.
		search.mTarget = unsigned(rand() % mEnemies.GetNumEntries());

		unsigned count = FindEnemy(mEnemies, ByIndex, search);

		// If the collection is sparse, the search may fail. If it does but the collection
		// is not empty, narrow against the used slot count and try again.
		if (!search.mEnemy && count > 0)
		{
			search.mTarget = unsigned(rand() % count);

			FindEnemy(mEnemies, ByIndex, search);
		}
	}

	/* Minimum hp enemy */
	else if (ap->StartsWith("enemy_min_hp:")) FindEnemy(mEnemies, ByMinHP, search);

	/* Maximum hp enemy */
	else if (ap->StartsWith("enemy_max_hp:")) FindEnemy(mEnemies, ByMaxHP, search);

	// If an enemy was found, send it the alert.
	if (search.mEnemy) SendPublicAlert(search.mEnemy, iParamA, iParamB);
}

/// Tells all enemies to enter or leave standby
/// @param bEnter If true, tell to enter
void SpawnPoint_cl::Standby (bool bEnter)
{
	ApplyAll(bEnter ? &Enemy_cl::EnterStandby : &Enemy_cl::LeaveStandby);
}
--]]

--[[
--
--
-- SpawnPoint_Messages.cpp
--
--
#include "stdafx.h"
#include "Game.h"
#include "actionlink.h"
#include "conditionlink.h"
#include "enemy.h"
#include "spawnpoint.h"
#include "timeoutcomponent.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>
#include "Lua_/Arg.h"
#include "Lua_/Helpers.h"
#include "Lua_/LibEx.h"
#include <Entities/TriggerBoxEntity.hpp>

/* Static bindings */
int SpawnPoint_cl::sEnemies = LUA_NOREF;

/* Condition links: deferred setup */
static LinkComponentData sLinks[] = {
	LinkComponentData("", 0, "")
};

/// Helper to lookup spawn point methods
struct Method {
	void (SpawnPoint_cl::*mFunc)(lua_State *);	///< Method pointer
};

/// Alert handler
/// @param what Alert name
/// @param iParam Optional alert-specific payload
void SpawnPoint_cl::Alert (lua_State * L, const StrComp & what, INT_PTR iParam)
{
	/* Get the proxy */
	if (what == "proxy") PushProxy(L);	// ..., proxy

	/* Follow-up */
	else if (what == "follow_up:action")
	{
		Method * pMethod = (Method *)((ActionLink_cl::FollowUpArgs *)iParam)->mInvokee->GetUserData();

		if (pMethod) (this->*pMethod->mFunc)(L);
	}

	/* Removed enemy */
	else if (what == "killed" || what == "retired") RemoveEnemy((Enemy_cl *)iParam, what == "killed");

	/* Standby */
	else if (what == "standby") Standby(iParam != FALSE);

	/* Get variety */
	else if (what == "get_variety") *(VString *)iParam = Variety;
}

/// Sends alerts to all reference entities
/// @param what Alert name
/// @param iParam Optional alert-specific payload
void SpawnPoint_cl::AlertAllRefs (const char * what, INT_PTR iParam)
{
	for (int i = 0; i < mRefEntities.GetLength(); ++i)
	{
		VisBaseEntity_cl * pEntity = mRefEntities.GetPtrs()[i];

		VASSERT(pEntity);

		SendAlert(pEntity, what, iParam);
	}
}

/// Cleanup logic
void SpawnPoint_cl::CleanUp (lua_State * L)
{
	RemoveAll(false, true);

	lua_unref(L, mRefProxy);
}

/// Commit logic
void SpawnPoint_cl::Commit (lua_State * L)
{
	// The spawn point begins disabled if the max spawn count is 0 or it fails the "is
	// enabled" condition. Trip the trigger corresponding to this state.
	bool bDisabled = IsClear() || !mIsEnabledWhenZoneEntered->Invoke();

	Trigger(NULL, bDisabled ? mDisable : mEnable);
}

/// Remaining message handler cases
void SpawnPoint_cl::DefaultCase (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	// Get Links: iParamA = VShapeLinkConfig *
	if (VIS_MSG_EDITOR_GETLINKS == iID)
	{
		LinkBuilder lb(iParamA);

		lb	.AddSource(&mEntityUniqueIds, "attach_to_entity", "Link to helper entities")
			.AddSource(&mPathUniqueIds, "attach_to_path", "Link to helper paths");

		ConditionLink_cl::Configure(sLinks, iParamA);
	}

	// Can Link / On Link / On Unlink: iParamA = VShapeLink *
	else if (VIS_MSG_EDITOR_CANLINK == iID || VIS_MSG_EDITOR_ONLINK == iID || VIS_MSG_EDITOR_ONUNLINK == iID)
	{
		// Handle links to reference entities or paths.
		VShapeLink * pLink = (VShapeLink *)iParamA;

		void * ud = pLink->m_LinkInfo.GetUserData();

		if (ud == &mEntityUniqueIds || ud == &mPathUniqueIds)
		{
			if (VIS_MSG_EDITOR_CANLINK == iID)
			{
				VType * pType = ud == &mPathUniqueIds ? V_RUNTIME_CLASS(VisPath_cl) : V_RUNTIME_CLASS(VisBaseEntity_cl);

				pLink->m_bResult = pLink->m_pOtherObject && pLink->m_pOtherObject->IsOfType(pType);
			}

			else ManageObjectID((VisObject3D_cl *)pLink->m_pOtherObject, *(DynArray_cl<__int64> *)ud, VIS_MSG_EDITOR_ONUNLINK == iID);
		}

		// Otherwise, try conditions.
		else ConditionLink_cl::ManageLinkTo(this, iID, iParamA);
	}
}

// Helper to add a string to the enumeration list
static void AddString (const char * prefix, const char * suffix, INT_PTR iParam)
{
	VString str;

	str.Format("%s%s", prefix, suffix);

	((VStrList*) iParam)->AddString(str);
}

// Helper to merge spawn point and enemy lists
static void MergeLists (const StrComp & what, const char ** choices, int n, void (*enum_func)(const StrComp &, INT_PTR), INT_PTR iParam)
{
	// Enumerate enemy choices.
	VStrList enemy_list;

	enum_func(what, INT_PTR(&enemy_list));

	// Add each spawn point choice normally, plus a version for enemies.
	DO_STR_ARRAY(sp_prefixes, i, "", "sp:")
	{
		for (int j = 0; j < n; ++j) AddString(sp_prefixes[i], choices[j], iParam);
	}

	// Add each enemy choice normally, plus versions for spawn points.
	DO_STR_ARRAY(enemy_prefixes, i, "", "enemy:", "enemy?:", "enemy_min_hp:", "enemy_max_hp:")
	{
		for (int j = 0; j < enemy_list.GetLength(); ++j) AddString(enemy_prefixes[i], enemy_list[j], iParam);
	}
}

/// @param iParam [out] @b VStrList to populate with available alerts
void SpawnPoint_cl::EnumAlerts (const StrComp & what, INT_PTR iParam)
{
	MergeLists(what, NULL, 0, &Enemy_cl::EnumAlerts, iParam);
}

/// @param iParam [out] @b VStrList to populate with available properties
void SpawnPoint_cl::EnumProperties (const StrComp & what, INT_PTR iParam)
{
	const char * num_props[] = {
		"active_percentage", "max_active", "num_active",
		"max_spawns", "num_spawns",
		"killed_percentage", "num_killed",
		"left_to_kill_percentage", "num_left_to_kill",
		"left_to_spawn_percentage", "num_left_to_spawn"
	};

	bool bEnumNumbers = what == "enum_properties:number";

	MergeLists(what, bEnumNumbers ? num_props : NULL, bEnumNumbers ? ArrayN(num_props) : 0, &Enemy_cl::EnumProperties, iParam);
}

/// @param iParam [out] @b VStrList to populate with AI varieties
void SpawnPoint_cl::EnumVarieties (lua_State * L, INT_PTR iParam)
{
	FindModelEntry(L);	// ..., entry

	PopulateDropdownFromLuaTableKeys(L, iParam, "scripts");

	lua_pop(L, 1);	// ...
}

/// Loads or saves mutable spawn point state to persist across check points
void SpawnPoint_cl::MemArchive (VArchive & ar)
{
	TimeoutComponent_cl * comps[] = { mState.mDrowse, mState.mEmit, mState.mWait };

	if (ar.IsLoading())
	{
		//LoadBitfield(ar, mFlags);

		ar >> mState.mNumSpawns;

		for (int i = 0; i < ArrayN(comps); ++i) comps[i]->MemLoad(ar);

		// TODO: Next step?
	}

	else
	{
		//SaveBitfield(ar, mFlags);

		ar << mState.mNumSpawns - mState.mNumActive;

		for (int i = 0; i < ArrayN(comps); ++i) comps[i]->MemSave(ar);
	}
}

/// @param bFirst If true, this is the first instantiated spawn point
void SpawnPoint_cl::NewInstance (lua_State * L, BOOL bFirst)
{
	static LinkComponentData sActions[] = {
		LINK_DATA_EX(SpawnPoint_cl, OnClear, "Spawn point got cleared", "Textures/Editor/sp_onclear.dds"),
		LINK_DATA_EX(SpawnPoint_cl, OnDisable, "Spawn point got disabled", "Textures/Editor/e_ondisable.dds"),
		LINK_DATA_EX(SpawnPoint_cl, OnKill, "An enemy got killed", "Textures/Editor/sp_onkill.dds"),
		LINK_DATA_EX(SpawnPoint_cl, OnReset, "Spawn point got reset", "Textures/Editor/sp_onreset.dds"),
		LINK_DATA_EX(SpawnPoint_cl, OnSleep, "Spawn point went to sleep", "Textures/Editor/sp_onsleep.dds"),
		LINK_DATA_EX(SpawnPoint_cl, OnSpawn, "An enemy was spawned", "Textures/Editor/sp_onspawn.dds"),
		LINK_DATA_EX(SpawnPoint_cl, OnWake, "Spawn point woke up", "Textures/Editor/sp_onwake.dds")
	};

	static LinkComponentData sTargets[] = {
		/* Touch */
		LINK_DATA_EX(SpawnPoint_cl, AddOneTouch, "Add a touch to the spawn point", "Textures/Editor/sp_addonetouch.dds"),
		LINK_DATA_EX(SpawnPoint_cl, RemoveOneTouch, "Remove a touch from the spawn point", "Textures/Editor/sp_removeonetouch.dds"),
		LINK_DATA_EX(SpawnPoint_cl, Impulse, "Apply an impulse to the spawn point (touch, then untouch)", "Textures/Editor/sp_impulse.dds"),

		/* Enabled */
		LINK_DATA_EX(SpawnPoint_cl, Disable, "Disable the spawn point", "Textures/Editor/e_disable.dds"),
		LINK_DATA_EX(SpawnPoint_cl, Enable, "Enable the spawn point", "Textures/Editor/e_enable.dds")
	};

	mFlags.AllocateBitfield(_nFlagBits);

	SetupTriggerSources(this, sActions);
	SetupTriggerTargets(this, sTargets);

	if (bFirst) sLinks[0] = LINK_DATA_EX(SpawnPoint_cl, IsEnabledWhenZoneEntered, "Is spawn point enabled when you enter the zone?", NULL);

	ConditionLink_cl::SetupTargets(this, sLinks);

	mIsEnabledWhenZoneEntered->SetDefault(EnabledWhenZoneEntered != FALSE);

	// Add some method lookups.
	#define BIND_METHOD(name) static Method sMethod##name = { &SpawnPoint_cl::Post##name };	mOn##name##->SetUserData(&sMethod##name);

	BIND_METHOD(Clear);
	BIND_METHOD(Kill);
	BIND_METHOD(Sleep);
	BIND_METHOD(Spawn);
	BIND_METHOD(Wake);

	#undef BIND_METHOD

	// Couple the touch triggers and perform any convenience association.
	mTouchPair.Bind(mAddOneTouch, mRemoveOneTouch, LeaveByBoxToo != FALSE);

	/* First-time setup */
	if (bFirst)
	{
		RegisterCollectionAndContext(L, V_RUNTIME_CLASS(SpawnPoint_cl), "spawn_points");

		// In the editor, ensure the enemy lookup table is loaded.
		if (Vision::Editor.IsInEditor())
		{
			if (!Game_cl::GetMe()->DataDirectoriesRegistered()) Game_cl::GetMe()->RegisterDataDirectories();
			if (!Game_cl::GetMe()->BaseBindingsRegistered()) Game_cl::GetMe()->RegisterBaseBindings();

			DO_STR_ARRAY(files, i, "Config/Helpers.lua", "Config/Enemies.lua")
			{
				if (Lua::LoadFile(L, files[i]) != 0)	// ..., chunk_or_error
				{
					Vision::Error.Warning(Lua::S(L, -1));

					lua_pop(L, 1);	// ...

					break;
				}

				else lua_PCALL(L, 0, 0, 0);	// ...
			}
		}

		// Cache the enemy lookup table.
		lua_getglobal(L, "enemies");// ..., enemies

		sEnemies = lua_ref(L, true);// ...

		// Build a wrapper class for bindings.
		LUA_CreateWrapperClass(L, &sNativeClassInfo);
	}

	BindModel();
}

/// Helper logic to accompany enable or disable events
/// @param bManual If true, the event was triggered manually
/// @param bEnable If true, the spawn point was enabled
void SpawnPoint_cl::OnEnable (bool bManual, bool bEnable)
{
	if (AwakeIfEnabled) bEnable ? Wake() : Sleep();

	else if (!bManual) mTouchPair.Enable(this, bEnable);

	SetThinkFunctionStatus(bEnable);

	// If requested, remove the spawn point when it is disabled.
	if (!bEnable && RemoveOnDisable) Remove();
}

/// Public alert handler
/// @param what Alert name
/// @param iParam Alert packet
void SpawnPoint_cl::PublicAlert (const StrComp & what, INT_PTR iParam)
{
	AlertPacket * ap = (AlertPacket *)iParam;

	if (ap->mPayloadType != AlertPacket::eString) return;

	StrComp prop(ap->mPayload);

	/* Alert to enemy */
	if (VStringHelper::StartsWith(prop, "enemy")) SendAlertToEnemy(what, iParam);

	/* Otherwise, alert to spawn point */
	else if (what == "get_property:number")
	{
		lua_State * L = ap->mL;

		/* Active properties */
		if (prop == "active_percentage") lua_pushnumber(L, float(mState.mNumActive) / mState.mMaxActive);	// ..., active%
		else if (prop == "num_active") lua_pushinteger(L, mState.mNumActive);	// ..., active
		else if (prop == "max_active") lua_pushinteger(L, mState.mMaxActive);	// ..., max_active

		/* Spawn properties: only meaningful when spawning is finite */
		else if (mState.mMaxSpawns > 0)
		{
			int kills = mState.mNumSpawns - mState.mNumActive;
			int spawns_left = mState.mMaxSpawns - mState.mNumSpawns;
			int kills_left = mState.mMaxSpawns - kills;

			if (prop == "max_spawns") lua_pushinteger(L, mState.mMaxSpawns);// ..., max_spawns
			else if (prop == "num_spawns") lua_pushinteger(L, mState.mNumSpawns);	// ..., spawns;
			else if (prop == "killed_percentage") lua_pushnumber(L, float(kills) / mState.mMaxSpawns);	// ..., kill%
			else if (prop == "num_killed") lua_pushinteger(L, kills);	// ..., kills
			else if (prop == "left_to_kill_percentage") lua_pushnumber(L, float(kills_left) / mState.mMaxSpawns);	// kills_left%
			else if (prop == "num_left_to_kill") lua_pushinteger(L, kills_left);// kills_left
			else if (prop == "left_to_spawn_percentage") lua_pushnumber(L, float(spawns_left) / mState.mMaxSpawns);	// spawns_left%
			else if (prop == "num_left_to_spawn") lua_pushinteger(L, spawns_left);	// ..., spawns_left
		}
	}
}

/// Resets the spawn point
void SpawnPoint_cl::Reset ()
{
	RemoveAll(false);

	mState.mEmit->Reset();

	mState.mNumSpawns = 0;
	mPenaltyCount = 0;

	mOnReset->Invoke();
}

/// @param pSource Trigger source; if @b NULL, manual triggering is assumed and early-out guards are ignored
/// @param pTarget Trigger target, used to choose response
void SpawnPoint_cl::Trigger (VisTriggerSourceComponent_cl * pSource, VisTriggerTargetComponent_cl * pTarget)
{
	bool bManual = !pSource;

	VASSERT(bManual || IsCommitted(this));

	/* Enable */
	if (mEnable == pTarget && (IsBitSet_Flip(mFlags, DisabledFlag) || bManual))
	{
		if (0 == mState.mMaxSpawns) return;

		Reset();

		OnEnable(bManual, true);
	}

	// No further automatic events may occur when disabled.
	else if (mFlags.IsBitSet(DisabledFlag) && !bManual) return;

	/* Disable */
	else if (mDisable == pTarget)
	{
		mFlags.SetBit(DisabledFlag);

		RemoveAll(KillActive != FALSE);

		OnEnable(bManual, false);

		mOnDisable->Invoke();
	}

	// Touch is disregarded if waking and being enabled are synonymous.
	else if (!AwakeIfEnabled)
	{
		/* Impulse */
		if (mImpulse == pTarget)
		{
			Trigger(pSource, mAddOneTouch);
			Trigger(pSource, mRemoveOneTouch);
		}

		/* Add one touch */
		else if (mAddOneTouch == pTarget && mTouchCount++ == 0) Wake();

		/* Remove one touch */
		else if (mRemoveOneTouch == pTarget && DecrementOnTrigger(this, mTouchCount, "attempt to leave vacant spawn point proximity"))
		{
			mFlags.SetBit(DrowsyFlag);

			mState.mDrowse->Reset();
		}
	}
}

/// Export validation
void SpawnPoint_cl::Validate (INT_PTR iParam)
{
	// Has a valid model?
	// Numbers valid?
	// etc.
}
--]]