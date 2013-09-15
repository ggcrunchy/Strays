--- Failure node from C++.

--[[
--
--
-- FailureNode.h
--
--
#ifndef _FAILURE_NODE_CL
#define _FAILURE_NODE_CL

/// Node that may be tripped to signal a failed objective
class FailureNode_cl : public VisBaseEntity_cl {
public:
	FailureNode_cl (void);

	VOVERRIDE void InitFunction (void);
	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);

	V_DECLARE_SERIAL_DLLEXP(FailureNode_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(FailureNode_cl)

private:
	// vForge variables
	VString DescriptionKey;	///< Key used to look up description text, if any
	int Consequence;///< How to respond to failure

	// Implementation
	VSmartPtr<VisTriggerTargetComponent_cl> mFail;	///< Target to invoke failure
	__int64 mEventID;	///< Failure event, if any
};

#endif
--]]

--[[
--
--
-- FailureNode.cpp
--
--
#include "stdafx.h"
#include "failurenode.h"
#include "chainevent.h"
#include "entityhelpers.h"
#include "entitylinks.h"
#include "game.h"

/// Constructor
FailureNode_cl::FailureNode_cl (void) : mEventID(0)
{
}

/// Initialization
void FailureNode_cl::InitFunction (void)
{
	AssignNamedComponent(this, mFail, "Fail", VIS_OBJECTCOMPONENTFLAG_SERIALIZEWHENRELEVANT);
}

/// Message handler
void FailureNode_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	// Trigger: iParamA = VisTriggerSourceComponent_cl *, iParamB = VisTriggerTargetComponent_cl *
	if (VIS_MSG_TRIGGER == iID)
	{
		VASSERT(INT_PTR(mFail.GetPtr()) == iParamB);

		Game_cl::GetMe()->SetControlBool("failed", true);

		// EVENT?
	}

	// Other cases
	else
	{
		// Get Links: iParamA = VShapeLinkConfig *
		if (VIS_MSG_EDITOR_GETLINKS == iID)
		{
			LinkBuilder lb(iParamA);

			lb.	AddSource(&mEventID, "attach_to_event", "Link to failure event");
		}

		// Can Link / On Link / On Unlink: iParamA = VShapeLink *
		else ManageTypeLinkID(iID, iParamA, V_RUNTIME_CLASS(ChainEvent_cl), mEventID);

		VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
	}
}

/// Serialization
void FailureNode_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = BeginEntitySerialize(this, ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> DescriptionKey;
		ar >> Consequence;
		ar >> mEventID;
	}

	else
	{
		/* VERSION 1 */
		ar << DescriptionKey;
		ar << Consequence;
		ar << mEventID;
	}
}

/* FailureNode_cl variables */
V_IMPLEMENT_SERIAL(FailureNode_cl, VisBaseEntity_cl, 0, &gGameModule);

START_VAR_TABLE(FailureNode_cl, VisBaseEntity_cl, "Signal that crucial zone objective has been failed", VVARIABLELIST_FLAGS_NONE, "Models/failiure_node.MODEL")

	DEFINE_VAR_VSTRING(FailureNode_cl, DescriptionKey, "If the failure has a decription, look it up with this key", "", 0, 0, 0);
	DEFINE_VAR_ENUM(FailureNode_cl, Consequence, "What is the consequence of failure?", "Death", "Death", 0, 0);

END_VAR_TABLE
--]]