--- ENTITY_LINKS from C++.

--[[
--
--
-- EntityLinks.h
--
--
#ifndef _ENTITY_TRIGGERS
#define _ENTITY_TRIGGERS

// Forward references
struct lua_State;

/// Component lookup / output
struct LinkComponentData {
	LinkComponentData (const char * name, int offset, const char * display = NULL, const char * icon = NULL) : mDisplay(display), mIcon(icon), mName(name), mOffset(offset), mPtr(NULL)
	{
		mID = IVObjectComponent::RegisterStringID(name);
	}

	void AuxAddMetadata (VString & display, VString & icon)
	{
		if (!Vision::Editor.IsInEditor()) return;

		if (mDisplay) display = mDisplay;
		if (mIcon) icon = mIcon;
	}

	void AddMetadata (IVisTriggerBaseComponent_cl * pComp)
	{
		AuxAddMetadata(pComp->m_sVForgeDisplayName, pComp->m_sVForgeIconFilename);
	}

	void AddMetadata (VShapeLinkInfo * pInfo)
	{
		AuxAddMetadata(pInfo->m_sDisplayName, pInfo->m_sIconFilename);
	}

	const char * mDisplay;	///< vForge display name
	const char * mIcon;	///< vForge icon name
	const char * mName;	///< Component name
	void * mPtr;///< Pointer assigned during setup
	int mID;///< ID associated with name
	int mOffset;///< Trigger smart pointer offset
};

/// Helper to setup links
class LinkBuilder {
public:
	LinkBuilder (VShapeLinkConfig * pConfig);
	LinkBuilder (INT_PTR iParam);
	~LinkBuilder (void);

	LinkBuilder & AddSource (void * ud, const char * unique_id, const char * display, const char * icon = NULL);
	LinkBuilder & AddSource (int id, const char * unique_id, const char * display, const char * icon = NULL);
	LinkBuilder & AddTarget (void * ud, const char * unique_id, const char * display, const char * icon = NULL);
	LinkBuilder & AddTarget (int id, const char * unique_id, const char * display, const char * icon = NULL);

	void AddMetadataTo (LinkComponentData & link);
	void SetID (int id);
	void SetUserData (void * ud);

private:
	VShapeLinkInfo & AddCommon (const char * unique_id, const char * display, const char * icon);
	VShapeLinkInfo & MostRecent (void);

	VShapeLinkConfig * mConfig;	///< Link configuration
	VShapeLinkInfo mInfo[32];	///< Buffer for links
	int mCount;	///< Links in buffer
};

/// Helper to establish RAII-based invocation context for links
template<typename T> struct InvokeContext {
	InvokeContext (void) : mPrev(sCurrent) { sCurrent = this; }
	~InvokeContext (void) { sCurrent = mPrev; }

	static InvokeContext<T> * sCurrent;	///< Current invocation context

	VisTypedEngineObject_cl * mObject;	///< Object passed as argument
	T * mLink;	///< Invoking link
	InvokeContext * mPrev;	///< Previous context
	bool mIsProxy;	///< If true, @e mObject is a proxy object
};

/// Sets up action links and registers sources already present; in the editor, the sources are first added
/// @param pObject Object to receive sources
/// @param arr Data array
template<int count> void SetupTriggerSources (VisTypedEngineObject_cl * pObject, LinkComponentData (&arr)[count])
{
	for (int i = 0; i < count; ++i)
	{
		ActionLink_cl * pLink = FindComponentByName<ActionLink_cl>(pObject, arr[i].mName);

		if (!pLink)
		{
			pLink = new ActionLink_cl;

			pLink->SetComponentName(arr[i].mName);
			pObject->AddComponent(pLink);
		}

		VSmartPtr<ActionLink_cl> * link_sp = AtOffset<VSmartPtr<ActionLink_cl> >(pObject, arr[i].mOffset);

		*link_sp = pLink;

		if (FindSource(pObject, arr[i].mName) || !Vision::Editor.IsInEditor()) continue;

		VisTriggerSourceComponent_cl * pSource = new VisTriggerSourceComponent_cl(arr[i].mName, VIS_OBJECTCOMPONENTFLAG_SERIALIZEWHENRELEVANT);

		pSource->Initialize();

		pObject->AddComponent(pSource);

		arr[i].mPtr = pSource;

		arr[i].AddMetadata(pSource);
	}
}

/// Adds and registers missing link targets, as well as registering those already present
/// @param pObject Object to receive links
/// @param arr Data array
template<typename T, int count> void SetupLinkTargets (VisTypedEngineObject_cl * pObject, LinkComponentData (&arr)[count])
{
	for (int i = 0; i < count; ++i)
	{
		VSmartPtr<T> * spLT = AtOffset<VSmartPtr<T> >(pObject, arr[i].mOffset);

		T * pLT = FindComponentByName<T>(pObject, arr[i].mName);

		if (!pLT)
		{
			pLT = new T;

			pLT->SetComponentName(arr[i].mName);
			pLT->Initialize();

			pObject->AddComponent(pLT);

			arr[i].mPtr = pLT;
		}

		spLT->Set(pLT);
	}
}

/// Adds and registers missing trigger targets, as well as registering targets already present
/// @param pObject Object to receive targets
/// @param arr Data array
template<int count> void SetupTriggerTargets (VisTypedEngineObject_cl * pObject, LinkComponentData (&arr)[count])
{
	SetupLinkTargets<VisTriggerTargetComponent_cl>(pObject, arr);

	for (int i = 0; i < count; ++i) arr[i].AddMetadata((VisTriggerTargetComponent_cl *)arr[i].mPtr);
}

/// Helper to manage balanced trigger box-linked trigger targets; where balancing is not needed, serves basic needs of 0, 1, or 2 targets
class TriggerBoxPair {
public:
	TriggerBoxPair (void) : mBound(false) { mBoxLinks.SetDefaultValue(NULL); }

	void Bind (VisTriggerTargetComponent_cl * pEnter, VisTriggerTargetComponent_cl * pLeave, bool bBalance = true);
	void Enable (VisTypedEngineObject_cl * pOwner, bool bEnable);

private:
	DynArray_cl<IVisTriggerBaseComponent_cl *> mBoxLinks;	///< Trigger components, stored as (source, target) pairs, to link / unlink on enable
	bool mBound;///< If true, targets have been bound
};

/// Helper to declare link component data
#define LINK_DATA(klass, name) LinkComponentData(#name, offsetof(klass, m##name))

/// Helper to declare link component data, including metadata
#define LINK_DATA_EX(klass, name, display, icon) LinkComponentData(#name, offsetof(klass, m##name), display, icon)

VisTriggerSourceComponent_cl * FindSource (VisTypedEngineObject_cl * pObject, const char * name);
VisTriggerTargetComponent_cl * FindTarget (VisTypedEngineObject_cl * pObject, const char * name);

void SendTriggerMessage (VisTypedEngineObject_cl * pObject, VisTriggerTargetComponent_cl * pTarget, VisTriggerSourceComponent_cl * pSource = NULL);

bool DecrementOnTrigger(VisObjectKey_cl * pObject, int & var, const char * action = "do some action");

#endif
--]]

--[[
--
--
-- EntityLinks.cpp
--
--
#include "stdafx.h"
#include "entitylinks.h"
#include "entityhelpers.h"
#include "AppUtils.h"
#include <Entities/TriggerBoxEntity.hpp>

/// Constructor
LinkBuilder::LinkBuilder (VShapeLinkConfig * pConfig) : mConfig(pConfig), mCount(0)
{
	VASSERT(mConfig);
}

/// Constructor
LinkBuilder::LinkBuilder (INT_PTR iParam) : mConfig((VShapeLinkConfig *)iParam), mCount(0)
{
	VASSERT(mConfig);
}

/// Destructor
LinkBuilder::~LinkBuilder (void)
{
	if (0 == mCount) return;

	for (int i = 0, offset = mConfig->AllocateLinks(mCount); i < mCount; ++i)
	{
		VShapeLinkInfo & info = mConfig->GetLinkInfo(offset + i);

		info = mInfo[i];

		info.SetUserData(mInfo[i].GetUserData());
	}
}

///
/// @param ud
/// @param unique_id
/// @param display
/// @param icon
/// @return @e this, for chaining
LinkBuilder & LinkBuilder::AddSource (void * ud, const char * unique_id, const char * display, const char * icon)
{
	VShapeLinkInfo & info = AddCommon(unique_id, display, icon);

	info.SetUserData(ud);

	return *this;
}

///
/// @param id
/// @param unique_id
/// @param display
/// @param icon
/// @return @e this, for chaining
LinkBuilder & LinkBuilder::AddSource (int id, const char * unique_id, const char * display, const char * icon)
{
	VShapeLinkInfo & info = AddCommon(unique_id, display, icon);

	info.m_iCustomID = id;

	return *this;
}

///
/// @param ud
/// @param unique_id
/// @param display
/// @param icon
/// @return @e this, for chaining
LinkBuilder & LinkBuilder::AddTarget (void * ud, const char * unique_id, const char * display, const char * icon)
{
	VShapeLinkInfo & info = AddCommon(unique_id, display, icon);
		
	info.SetUserData(ud);
	
	info.m_eType = VShapeLinkInfo::LINK_TARGET;

	return *this;
}

///
/// @param id
/// @param unique_id
/// @param display
/// @param icon
/// @return @e this, for chaining
LinkBuilder & LinkBuilder::AddTarget (int id, const char * unique_id, const char * display, const char * icon)
{
	VShapeLinkInfo & info = AddCommon(unique_id, display, icon);

	info.m_eType = VShapeLinkInfo::LINK_TARGET;
	info.m_iCustomID = id;

	return *this;
}

/// @param link [out]
void LinkBuilder::AddMetadataTo (LinkComponentData & link)
{
	link.AddMetadata(&MostRecent());
}

/// @param id ID to explicitly assign
void LinkBuilder::SetID (int id)
{
	MostRecent().m_iCustomID = id;
}

/// @param ud User data to explicitly assign
void LinkBuilder::SetUserData (void * ud)
{
	MostRecent().SetUserData(ud);
}

///
/// @param unique_id
/// @param display
/// @param icon
/// @return
VShapeLinkInfo & LinkBuilder::AddCommon (const char * unique_id, const char * display, const char * icon)
{
	VASSERT_MSG(mCount < ArrayN(mInfo), "Buffer full");

	VShapeLinkInfo & info = mInfo[mCount++];

	info.m_sDisplayName = display;
	info.m_sUniqueStringID = unique_id;

	if (icon) info.m_sIconFilename = icon;

	return info;
}

///
/// @return
VShapeLinkInfo & LinkBuilder::MostRecent (void)
{
	VASSERT_MSG(mCount > 0, "No link info yet");

	return mInfo[mCount - 1];
}

// Helper to get a target's trigger box owner, if any
static TriggerBoxEntity_cl * GetTriggerBox (VisTriggerSourceComponent_cl * pSource)
{
	VASSERT(!pSource || pSource->GetOwner());

	return pSource && pSource->GetOwner()->IsOfType(TriggerBoxEntity_cl::GetClassTypeId()) ? (TriggerBoxEntity_cl *)pSource->GetOwner() : NULL;
}

/// Binds trigger box-based source-target links to allow for enabling and disabling as needed
/// @param pEnter If not @b NULL, the enter target
/// @param pLeave If not @b NULL, the leave target
/// @param bBalance If true, and neither target is @b NULL, any enter-type trigger box source linked to @a pEnter is balanced by the
/// corresponding leave-type source being linked to @a pLeave
/// @remark This is a one-time operation; the state is baked by this call and not to be altered
void TriggerBoxPair::Bind (VisTriggerTargetComponent_cl * pEnter, VisTriggerTargetComponent_cl * pLeave, bool bBalance)
{
	VASSERT(!mBound);
	VASSERT(!pEnter || pEnter->GetOwner());
	VASSERT(!pLeave || pLeave->GetOwner());

	// If both targets exist and balance is wanted, scan the enter target's sources. For any
	// trigger box-based enter source, make sure the corresponding leave source in that same
	// trigger box is linked to the leave target.
	if (bBalance && pEnter && pLeave)
	{
		for (int i = 0; i < pEnter->m_Sources.Count(); ++i)
		{
			VisTriggerSourceComponent_cl * pSource = (VisTriggerSourceComponent_cl *)pEnter->m_Sources.GetAt(i);
			TriggerBoxEntity_cl * pTB = GetTriggerBox(pSource);

			if (!pTB) continue;

			if (pTB->m_spOnCameraEnter == pSource) IVisTriggerBaseComponent_cl::OnLink(pTB->m_spOnCameraLeave, pLeave);
			if (pTB->m_spOnObjectEnter == pSource) IVisTriggerBaseComponent_cl::OnLink(pTB->m_spOnObjectLeave, pLeave);
		}
	}

	// Find any sources for whichever targets were provided that are trigger box-based and
	// collect these (source, target) pairs into the links list. This list provides for
	// enabling and disabling by manipulating the source-target links.
	DO_ARRAY(VisTriggerTargetComponent_cl *, targets, i, pEnter, pLeave)
	{
		if (targets[i]) for (int i = 0; i < targets[i]->m_Sources.Count(); ++i)
		{
			VisTriggerSourceComponent_cl * pSource = (VisTriggerSourceComponent_cl *)targets[i]->m_Sources.GetAt(i);

			if (GetTriggerBox(pSource))
			{
				mBoxLinks[mBoxLinks.GetFreePos()] = pSource;
				mBoxLinks[mBoxLinks.GetFreePos()] = targets[i];
			}
		}
	}

	// Seal the bindings.
	mBound = true;
}

/// Turns on or off all of its bound trigger box-based links
/// @param pOwner Owner, used for verification 
/// @param bEnable If true, bind all source-target links; otherwise, sever all of them
/// @remark This is a no-op until Bind() has been called
void TriggerBoxPair::Enable (VisTypedEngineObject_cl * pOwner, bool bEnable)
{
	VASSERT(pOwner);
	VASSERT(mBound || mBoxLinks.GetValidSize() == 0);
	VASSERT(mBoxLinks.GetValidSize() % 2 == 0);

	// Link or unlink all source-target pairs.
	TriggerBoxEntity_cl * pTB = NULL;

	for (unsigned i = 0, n = mBoxLinks.GetValidSize(); i < n; )
	{
		VisTriggerSourceComponent_cl * pSource = (VisTriggerSourceComponent_cl *)mBoxLinks.Get(i++);
		VisTriggerTargetComponent_cl * pTarget = (VisTriggerTargetComponent_cl *)mBoxLinks.Get(i++);

		if (!pTB) pTB = GetTriggerBox(pSource);

		VASSERT(pTB);
		VASSERT(pSource && pSource->GetOwner() == pTB);
		VASSERT(pTarget && pTarget->GetOwner() == pOwner);

		(bEnable ? IVisTriggerBaseComponent_cl::OnLink : IVisTriggerBaseComponent_cl::OnUnlink)(pSource, pTarget);

		// If an object is inside the trigger box when the link switches, manually trigger
		// it where appropriate: enters on enable, leaves on disable.
		bool bIsEnterSource = pSource == pTB->m_spOnCameraEnter || pSource == pTB->m_spOnObjectEnter;

		if (bEnable == bIsEnterSource) for (unsigned j = 0; j < pTB->m_EntitiesInside.GetSize(); ++j)
		{
			if (pTB->m_EntitiesInside.GetEntry(j) == pOwner) pTarget->OnTrigger(pSource);
		}
	}
}

///
/// @param pObject
/// @param name
/// @return
VisTriggerSourceComponent_cl * FindSource (VisTypedEngineObject_cl * pObject, const char * name)
{
	return FindComponentByName<VisTriggerSourceComponent_cl>(pObject, name);
}

///
/// @param pObject
/// @param name
/// @return
VisTriggerTargetComponent_cl * FindTarget (VisTypedEngineObject_cl * pObject, const char * name)
{
	return FindComponentByName<VisTriggerTargetComponent_cl>(pObject, name);
}

///
/// @param pObject
/// @param pTarget
/// @param pSource
void SendTriggerMessage (VisTypedEngineObject_cl * pObject, VisTriggerTargetComponent_cl * pTarget, VisTriggerSourceComponent_cl * pSource)
{
	Vision::Game.SendMsg(pObject, VIS_MSG_TRIGGER, INT_PTR(pSource), INT_PTR(pTarget));
}

/// Helper to decrement a number after a trigger and report errors on malformed setups
/// @param pObject Object that reacted to trigger, may be @b NULL if key is not important to report
/// @param var [in-out] Variable to decrement
/// @param action Action, to append to "attempt to" in any error message (should not contain control codes)
bool DecrementOnTrigger(VisObjectKey_cl * pObject, int & var, const char * action)
{
	if (0 == var)
	{ 
		VString name = pObject ? pObject->GetObjectKeySafe() : NULL;

		Vision::Error.Warning(VString("Malformed trigger setup: Attempt to ") + action + " '%s'", name.IsEmpty() ? "MISSING KEY" : name.AsChar());

		return false;
	}

	return 0 == --var;
}
--]]