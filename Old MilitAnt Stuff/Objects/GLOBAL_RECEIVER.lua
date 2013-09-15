--- Global receiver from C++.

--[[
--
--
-- GlobalReceiver.h
--
--
#include "stdafx.h"
#include "entitymanager.h"

// Helper to enumerate alerts
static void EnumAlerts (const char * alerts[], int iParam)
{
	for (int i = 0; alerts[i]; ++i) ((VStrList *)iParam)->AddString(alerts[i]);
}

/// Message handler
void GlobalReceiver_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	// Alert: iParamA = const char * or NULL, iParamB = AlertPacket *
	if (ID_OBJECT_PUBLIC_ALERT == iID)
	{
		AlertPacket * ap = (AlertPacket *)iParamB, name(ap->mL, StrComp(iParamA));

		if (name.StartsWith("get_property:")) Property(name.mPayload, ap);
		else if (name.StartsWith("effect:")) Effect(name.mPayload);
		else if (name.StartsWith("hud:")) HUD(name.mPayload);
		else if (name.StartsWith("music:")) Music(name.mPayload);
	}

	// Get Standard Values: iParamA = const char *, iParamB = VStrList *
	else if (VIS_MSG_EDITOR_GETSTANDARDVALUES == iID)
	{
		StrComp what(iParamA);

		/* Enumerate action alerts */
		if (what == "enum_alerts:action")
		{
			const char * alerts[] = {
				"effect:fade_in", "effect:fade_out",
				"hud:clip", "hud:flavor_text",
				"music:less_intense", "music:more_intense",
				NULL
			};

			EnumAlerts(alerts, iParamB);
		}

		/* Enumerate condition alerts */
		// TODO: This may just be a synonym for global boolean properties, unless there's a user-defined lookup
		else if (what == "enum_alerts:condition")
		{
			const char * alerts[] = { NULL };

			EnumAlerts(alerts, iParamB);
		}
	}

	// Other cases
	else VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
}

/// Global access
GlobalReceiver_cl * GlobalReceiver_cl::GetMe (void)
{
	static VWeakPtr<VisBaseEntity_cl> sReceiver;

	if (!sReceiver)
	{
		VisBaseEntity_cl * pReceiver = Vision::Game.CreateEntity("GlobalReceiver_cl", VisVector_cl());

		pReceiver->SetVisibleBitmask(VIS_ENTITY_INVISIBLE);

		sReceiver = pReceiver->GetWeakReference();
	}

	return (GlobalReceiver_cl *)sReceiver.GetPtr();
}

///
void GlobalReceiver_cl::Effect (const StrComp & what)
{
}

///
void GlobalReceiver_cl::HUD (const StrComp & what)
{
}

///
void GlobalReceiver_cl::Music (const StrComp & what)
{
}

///
void GlobalReceiver_cl::Property (const StrComp & what, const AlertPacket * ap)
{
	if (ap->mPayloadType != AlertPacket::eString) return;

	StrComp payload(ap->mPayload);

	/* Boolean properties */
	if (what == "boolean")
	{
		/* Is co-op */
		/* Is timed */
	}

	/* Number properties */
	else if (what == "number")
	{
		/* Zone time */
		/* Scene time */
		/* Time since load */
		/* Play time */
		/* Clock time */
		/* Number of players */
		/* Continues remaining */
		/* Time remaining */
	}
}

/* GlobalReceiver_cl variables */
V_IMPLEMENT_DYNCREATE(GlobalReceiver_cl, VisBaseEntity_cl, &gGameModule);

START_VAR_TABLE(GlobalReceiver_cl, VisBaseEntity_cl, "", VFORGE_HIDECLASS, "defaultBox")

END_VAR_TABLE
--]]