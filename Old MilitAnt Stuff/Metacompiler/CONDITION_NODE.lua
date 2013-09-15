--- Condition node from C++.

--[[
--
--
-- ConditionNode.h
--
--
#ifndef _CONDITION_NODE_CL
#define _CONDITION_NODE_CL

// Forward references
struct lua_State;

class ConditionComponent_cl;

/// Game state-based conditions that may be polled
class ConditionNodeBase_cl : public VisBaseEntity_cl {
public:
	V_DECLARE_DYNCREATE(ConditionNodeBase_cl)
	IMPLEMENT_OBJ_CLASS(ConditionNodeBase_cl)

	VOVERRIDE void MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB);

	bool MakeListing (void) const { return ShouldMakeListing != FALSE; }

protected:
	BOOL HasFewerThan (int n, VString & sErrorMsgOut, const char * message);

	char CommonSerialize (VArchive & ar, char iLocalVersion);

	void PushN (lua_State * L, int n);

	virtual void Push (lua_State * L) = 0;
	virtual void Validate (INT_PTR iParam) = 0;

	// vForge variables
	BOOL ShouldMakeListing;	///< If true and possible, a code listing is generated when this node is tripped
};

/// Conditions with a single clause
class ConditionNode_cl : public ConditionNodeBase_cl {
public:
	VOVERRIDE BOOL CanAddComponent (IVObjectComponent * pComp, VString & sErrorMsgOut);

	V_DECLARE_SERIAL_DLLEXP(ConditionNode_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(ConditionNode_cl)

private:
	virtual void Push (lua_State * L);
	virtual void Validate (INT_PTR iParam);
};

/// Conditions with two clauses
class BinaryConditionNode_cl : public ConditionNodeBase_cl {
public:
	VOVERRIDE BOOL CanAddComponent (IVObjectComponent * pComp, VString & sErrorMsgOut);

	V_DECLARE_SERIAL_DLLEXP(BinaryConditionNode_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(BinaryConditionNode_cl)

private:
	virtual void Push (lua_State * L);
	virtual void Validate (INT_PTR iParam);

	// vForge variables
	int Connective;	///< Index for @b "conditions:binary_connective" operation
};

/// Conditions with an arbitrary number of clauses and expression-based connectives
class CompoundConditionNode_cl : public ConditionNodeBase_cl {
public:
	static CompoundConditionNode_cl * FromObject (VisTypedEngineObject_cl * pObject, const VString & expr);

	static void ValidateExpression (VisTypedEngineObject_cl * pObject, const VString & expr, INT_PTR iParam, bool bAllowEmpty = true);

	V_DECLARE_SERIAL_DLLEXP(CompoundConditionNode_cl, G2GAME_IMPEXP)
	VOVERRIDE void Serialize (VArchive & ar);

	IMPLEMENT_OBJ_CLASS(CompoundConditionNode_cl)

private:
	/// Result of a successful ProcessExpression() call
	struct ProcessResult {
		ProcessResult (bool bGetData = true) : mCount(0), mGetData(bGetData) {}

		DynArray_cl<ConditionComponent_cl *> mComps;///< Components collected during processing
		VString mString;///< On success, parsed expression, with labels replaced by format specifiers; otherwise, the error
		int mCount;	///< Component count
		bool mGetData;	///< If true, @e mComps and @e mString are filled during processing
	};

	virtual void Push (lua_State * L);
	virtual void Validate (INT_PTR iParam);

	static bool ProcessExpression (VisTypedEngineObject_cl * pObject, const VString & expr, ProcessResult & result);

	// vForge variables
	VString Expression;	///< Glue expression for components (labels, connectives, operators, grouping)
};

#endif
--]]

--[[
--
--
-- ConditionNode.cpp
--
--
#include "stdafx.h"
#include "conditionnode.h"
#include "conditionlink.h"
#include "condition_components/conditioncomponents.h"
#include "entitylinks.h"
#include "entityhelpers.h"
#include <vScript/VScriptManager.hpp>

/// Message handler
void ConditionNodeBase_cl::MessageFunction (int iID, INT_PTR iParamA, INT_PTR iParamB)
{
	lua_State * L = VScriptRM()->GetMasterState();

	switch (iID)
	{
	// Alert: iParamA = const char * or NULL, iParamB = const void * or NULL
	case ID_OBJECT_ALERT:
		if (StrComp(iParamA) == "push") Push(L);

		break;

	// Validate export: iParamA = VisBeforeSceneExportedObject_cl *
	case ID_OBJECT_VALIDATE_EXPORT:
		Validate(iParamA);

		break;

	// Other cases
	default:
		// Get Links: iParamA = VShapeLinkConfig *
		if (VIS_MSG_EDITOR_GETLINKS == iID)
		{
			LinkBuilder lb(iParamA);

			/* Targets */
			lb	.AddTarget(V_RUNTIME_CLASS(VisBaseEntity_cl), "attach_from_link", "Attach from condition link");
		}

		// Can Link / On Link / On Unlink: iParamA = VShapeLink *
		else ConditionLink_cl::ManageLinkFrom(this, iID, iParamA);

		VisBaseEntity_cl::MessageFunction(iID, iParamA, iParamB);
	}
}

/// Helper for asking if slots are available for condition components
BOOL ConditionNodeBase_cl::HasFewerThan (int n, VString & sErrorMsgOut, const char * message)
{
	VASSERT(Components().Count() <= n);

	if (Components().Count() == n)
	{
		sErrorMsgOut = message;

		return FALSE;
	}

	return TRUE;
}

/// Common node serialization
char ConditionNodeBase_cl::CommonSerialize (VArchive & ar, char iLocalVersion)
{
	char iReadVersion = BeginEntitySerialize(this, ar, iLocalVersion);

	if (ar.IsLoading())
	{
		ar >> ShouldMakeListing;
	}

	else
	{
		/* VERSION 1 */
		ar << ShouldMakeListing;
	}

	return iReadVersion;
}

/// Helper to push the first @a n condition components
void ConditionNodeBase_cl::PushN (lua_State * L, int n)
{
	int count = 0;

	for (int i = 0; i < Components().Count(); ++i)
	{
		IVObjectComponent * pComp = Components().GetPtrs()[i];

		if (!pComp) continue;

	#ifdef NDEBUG	// In release, don't bother with sanity check
		VASSERT(count < n);
	#endif

		lua_pushlightuserdata(L, pComp);// ..., conds

		++count;
	}

	VASSERT(n == count);
}

/// Metacompiler push logic
void ConditionNode_cl::Push (lua_State * L)
{
	PushN(L, 1);// comp
}

/// Export validation
void ConditionNode_cl::Validate (INT_PTR iParam)
{
	if (CountComponents(this, V_RUNTIME_CLASS(ConditionComponent_cl)) != 1) FailValidation(iParam, "Expected single condition component");
}

/// Component add permissions
BOOL ConditionNode_cl::CanAddComponent (IVObjectComponent * pComp, VString & sErrorMsgOut)
{
	if (!VisTypedEngineObject_cl::CanAddComponent(pComp, sErrorMsgOut)) return FALSE;

	return !pComp->IsOfType(V_RUNTIME_CLASS(ConditionComponent_cl)) || HasFewerThan(1, sErrorMsgOut, "Condition nodes only accept one component");
}

/// Serialization
void ConditionNode_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);
}

/// Metacompiler push logic
void BinaryConditionNode_cl::Push (lua_State * L)
{
	PushN(L, 2);// cond1, cond2

	lua_pushstring(L, GetEnumValue(this, "Connective", Connective));// cond1, cond2, conn
}

/// Export validation
void BinaryConditionNode_cl::Validate (INT_PTR iParam)
{
	int count = CountComponents(this, V_RUNTIME_CLASS(ConditionComponent_cl));

	if (count != 2) FailValidation(iParam, "Expected two condition components, got %i", count);
}

/// Component add permissions
BOOL BinaryConditionNode_cl::CanAddComponent (IVObjectComponent * pComp, VString & sErrorMsgOut)
{
	if (!VisTypedEngineObject_cl::CanAddComponent(pComp, sErrorMsgOut)) return FALSE;

	return !pComp->IsOfType(V_RUNTIME_CLASS(ConditionComponent_cl)) || HasFewerThan(2, sErrorMsgOut, "Binary condition nodes only accept two components");
}

/// Serialization
void BinaryConditionNode_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Connective;
	}

	else
	{
		/* VERSION 1 */
		ar << Connective;
	}
}

/// Metacompiler push logic
void CompoundConditionNode_cl::Push (lua_State * L)
{
	ProcessResult result;

	bool bProcessed = ProcessExpression(this, Expression, result);

	VASSERT(bProcessed);

	lua_pushstring(L, result.mString);	// ..., resolved_expr

	for (int i = 0; i < result.mCount; ++i) lua_pushlightuserdata(L, result.mComps.GetDataPtr()[i]);// ..., resolved_expr, ..., pComp
}

/// Export validation
void CompoundConditionNode_cl::Validate (INT_PTR iParam)
{
	ValidateExpression(this, Expression, iParam, false);
}

/// Serialization
void CompoundConditionNode_cl::Serialize (VArchive & ar)
{
	const char VERSION = 1;

	char iReadVersion = CommonSerialize(ar, VERSION);

	if (ar.IsLoading())
	{
		ar >> Expression;
	}

	else
	{
		/* VERSION 1 */
		ar << Expression;
	}
}

/* ConditionNodeBase_cl variables */
V_IMPLEMENT_DYNAMIC(ConditionNodeBase_cl, VisBaseEntity_cl, &gGameModule);

START_VAR_TABLE(ConditionNodeBase_cl, VisBaseEntity_cl, "", VFORGE_HIDECLASS, "defaultBox")

	DEFINE_VAR_BOOL(ConditionNodeBase_cl, ShouldMakeListing, "Should a code listing be made when compiling against this node?", "FALSE", 0, 0);

END_VAR_TABLE

/* ConditionNode_cl variables */
V_IMPLEMENT_SERIAL(ConditionNode_cl, ConditionNodeBase_cl, 0, &gGameModule);

START_VAR_TABLE(ConditionNode_cl, ConditionNodeBase_cl, "Condition that evaluates a single clause (or fails with no clause)", VVARIABLELIST_FLAGS_NONE, "Models/condition_node.MODEL")

END_VAR_TABLE

/// Logical connective operations
static const char * ConnectiveOps = "And,Or,NAnd,NOr,Xor,Iff,Implies,NImplies,ConverseImplies,NConverseImplies";

/* BinaryConditionNode_cl variables */
V_IMPLEMENT_SERIAL(BinaryConditionNode_cl, ConditionNodeBase_cl, 0, &gGameModule);

START_VAR_TABLE(BinaryConditionNode_cl, ConditionNodeBase_cl, "Condition that evaluates two clauses", VVARIABLELIST_FLAGS_NONE, "Models/binary_condition_node.MODEL")

	DEFINE_VAR_ENUM(BinaryConditionNode_cl, Connective, "How are the two clauses connected?", "And", ConnectiveOps, 0, 0);

END_VAR_TABLE

/* CompoundConditionNode_cl variables */
V_IMPLEMENT_SERIAL(CompoundConditionNode_cl, ConditionNodeBase_cl, 0, &gGameModule);

START_VAR_TABLE(CompoundConditionNode_cl, ConditionNodeBase_cl, "Condition that evaluates arbitrary (labeled) clauses", VVARIABLELIST_FLAGS_NONE, "Models/compound_condition_node.MODEL")

	DEFINE_VAR_VSTRING(CompoundConditionNode_cl, Expression, "Expression describing clause connections", "", 0, 0, 0);

END_VAR_TABLE

// Load condition enums.
STATIC_ENUM_GROUP(ConditionEnums_,
	{ "conditions:binary_connective", ConnectiveOps }
);
--]]

--[[
--
--
-- ConditionNode_Parser.cpp
--
--
#include "stdafx.h"
#include "conditionnode.h"
#include "condition_components/conditioncomponents.h"
#include "entityhelpers.h"
#include "Lua_/Lua.h"

/// State of a condition glue expression parse
class ParseState {
public:
	ParseState (void);

	bool Parse (VisTypedEngineObject_cl * pObject, const VString & expr);

	const DynArray_cl<ConditionComponent_cl *> & GetComponents (void) const { return mComps; }
	const VString & GetStream (void) const { return mStream; }

private:
	void AddToken (char c) { mStream += c; }

	bool Error (const char * error, ...);
	bool ParseExpression (const char * str, DynArray_cl<int> & label_ranges);
	bool ParseKeyword (const char * word, int len);
	bool WasLabelOrRParen (void);

	// Implementation
	DynArray_cl<ConditionComponent_cl *> mComps;///< Components associated with labels
	VString mStream;///< Stream compiled during parse, or error string on failure
	bool mInError;	///< If true, an error occurred
};

/// Constructor
ParseState::ParseState (void) : mInError(false)
{
	mComps.Init(NULL);
}

/// Puts the parse state into an error mode and stores the error message
/// @param str Error string, which can include format codes
/// @param ... Additional error arguments
/// @return @b false, for convenience as return value
bool ParseState::Error (const char * str, ...)
{
	// Replace the stream with the error.
	va_list args;

	va_start(args, str);

	mStream.FormatArgList(str, args);

	va_end(args);

	// Put the state into error mode.
	mInError = true;

	return false;
}

/// Helper to process keywords and ensure expression integrity
/// @param word Pointer to beginning of word
/// @param len Length of word (as @a word in general will not be not null-terminated)
/// @return If true, the word is a keyword
bool ParseState::ParseKeyword (const char * word, int len)
{
	bool bFollow = WasLabelOrRParen();

	DO_ARRAY(struct {
		const char * mWord;	///< Keyword string
		char mToken;///< Keyword shorthand token
		bool mFollow;	///< If true, keyword must follow label / right parenthesis; otherwise, it cannot
	}, keywords, i,
		{ "and", '&', true },
		{ "or", '|', true },
		{ "not", '~', false }
	) {
		if (strncmp(word, keywords[i].mWord, len) != 0) continue;

		if (keywords[i].mFollow == bFollow) AddToken(keywords[i].mToken);

		else Error("Keyword '%s' %s follow a ')' or a label", keywords[i].mWord, keywords[i].mFollow ? "must" : "cannot");

		return true;
	}

	return false;
}

/// Expression parsing body; tokens are added to the stream
/// @param str String to parse
/// @param label_ranges [out] Storage for <begin, end> offset pairs for label substrings
/// @return If true, expression was well-formed
bool ParseState::ParseExpression (const char * str, DynArray_cl<int> & label_ranges)
{
	for (int i = 0, lindex = 0, parens = 0, begin = -1; ; ++i)
	{
		char ec = str[i];

		// Do non-label / non-keyword logic on encountering a space or parenthesis. The
		// null terminator is also handled here in case the expression ends with a label.
		if ('(' == ec || ')' == ec || isspace(ec) || !ec)
		{
			// If a word has been forming, stop doing so and classify it.
			if (begin != -1)
			{
				VASSERT(begin < i);

				// Check whether the word is a keyword and handle it if so. Otherwise, the
				// word is a label and its range is stored.
				if (!ParseKeyword(str + begin, i - begin))
				{
					if (WasLabelOrRParen()) return Error("Label cannot follow a ')' or another label (separate with 'and' / 'or')");

					label_ranges.GetDataPtr()[lindex++] = begin;
					label_ranges.GetDataPtr()[lindex++] = i - 1;

					AddToken('L');
				}

				// If a keyword error occurred, quit.
				else if (mInError) return false;

				// Stop forming word.
				begin = -1;
			}

			// Terminate the loop on the null character. Includes special case for empty expression.
			if (!ec)
			{
				if (parens > 0) return Error("Dangling '(': missing one or more ')' characters");
				if (i > 0 && !WasLabelOrRParen()) return Error("Last term must be a ')' or a label");

				break;
			}

			// In the case of either parenthesis, open or close the pair and append the token
			// to the stream. Spaces leave the stream intact.
			else if (!isspace(ec))
			{
				if ('(' == ec)
				{
					if (WasLabelOrRParen()) return Error("Label or ')' cannot precede a '('");

					++parens;
				}

				else
				{
					if (!WasLabelOrRParen()) return Error("Label or other ')' must precede a ')'");
					if (--parens < 0) return Error("Unbalanced ')': does not match a '('");
				}

				AddToken(ec);
			}
		}

		// Otherwise, continue the word or start a new one. Verification against the
		// previous token must wait until the word has been classified.
		else
		{
			if (-1 == begin) begin = i;

			if (ec != '_' && !isalnum(ec)) return Error("Label or keyword must contain only '_', letters, or digits");
		}
	}

	return true;
}

/// Common previous term case
/// @return If true, the last term was a label or a right parenthesis
bool ParseState::WasLabelOrRParen (void)
{
	return mStream.EndsWith(')') || mStream.EndsWith('L');
}

/// Parses an expression and builds a list of condition components matching embedded labels
/// @param pObject Once labels have been enumerated, condition lookup is performed in its component list
/// @param expr Expression to parse
/// @return If true, parse was successful or @a expr is empty
bool ParseState::Parse (VisTypedEngineObject_cl * pObject, const VString & expr)
{
	// An empty expression is trivially successful.
	if (expr.IsEmpty()) return true;

	// Try to parse the expression. The label range array size will be just enough when the
	// expression is just a single-character label, and otherwise is safely overestimated.
	DynArray_cl<int> label_ranges(expr.GetLength() * 2, -1);

	if (!ParseExpression(expr, label_ranges)) return false;

	// Cache labeled condition component indices. Again, the array is usually overestimated,
	// but will be filled if the list consists completely of condition components.
	DynArray_cl<ConditionComponent_cl *> comps(pObject->Components().Count(), NULL);

	unsigned comps_size = 0;

	for (unsigned i = 0; i < comps.GetSize(); ++i)
	{
		IVObjectComponent * pComp = pObject->Components().GetPtrs()[i];

		if (pComp && pComp->IsOfType(V_RUNTIME_CLASS(ConditionComponent_cl))) comps[comps_size++] = (ConditionComponent_cl *)pComp;
	}

	// Try to pair each label with a condition component.
	unsigned range_size = label_ranges.GetValidSize();

	VASSERT(range_size % 2 == 0);

	mComps.Resize(range_size / 2);

	for (unsigned i = 0; i < range_size; i += 2)
	{
		VString label;

		label.Left(expr.AsChar() + label_ranges[i], label_ranges[i + 1] - label_ranges[i] + 1);

		for (unsigned j = 0; j < comps_size; ++j)
		{
			if (!comps[j]->MatchesLabel(label)) continue;

			if (mComps.Get(i / 2)) return Error("Object has multiple condition components matching label: %s", label.AsChar());

			mComps.GetDataPtr()[i / 2] = comps[j];
		}

		// Check for failed matches.
		if (!mComps.Get(i / 2)) return Error("Object has no condition component matching label: %s", label.AsChar());
	}

	return true;
}

/// Processes a conditional expression and, on success, stores the results for further use
/// @param pObject Owner of any condition components referenced by the expression
/// @param expr Conditional expression that glues together 0 or more labeled condition components
/// @param result [in-out] On success, the results of the process
/// @return If true, processing succeeded
/// @remark An expression can be composed of the following terms: <b>(</b> <b>)</b> @b and @b or @b not
/// @remark Other words (i.e. any combination of letters, digits, and underscores) are interpreted as labels
/// @remark Given the above, the expression must compile as <b>return @a expr</b> in Lua
/// @remark Labels are ignored during compilation, being replaced by their condition's expansion
/// @remark Furthermore, if a label appears more than once, each instance is thus expanded
bool CompoundConditionNode_cl::ProcessExpression (VisTypedEngineObject_cl * pObject, const VString & expr, ProcessResult & result)
{
	// Attempt to parse the expression. On failure, save the error and quit.
	ParseState state;

	if (!state.Parse(pObject, expr))
	{
		result.mString = state.GetStream();

		return false;
	}

	// If the data is wanted, copy the component list and expand the stream.
	if (result.mGetData)
	{
		result.mComps = state.GetComponents();

		// Get the expression string rebuilt with format specifiers in place of the labels,
		// now that those are collected in-order in the components list.
		const VString & stream = state.GetStream();

		for (int i = 0, n = stream.GetLength(); i < n; ++i)
		{
			char cc = stream[i];

			// Labels (guard expansions with parentheses following a "not")
			if ('L' == cc)
			{
				result.mString += i > 0 && '~' == stream[i - 1] ? "(%s)" : "%s"; 

				++result.mCount;
			}

			// Keywords
			else if ('&' == cc)	result.mString += " and ";
			else if ('|' == cc)	result.mString += " or ";
			else if ('~' == cc)	result.mString += "not ";

			// Parentheses
			else result.mString += cc;
		}
	}

	return true;
}

/// Validates that the expression and condition components yield a valid condition node
/// @param pObject Owner of any condition components referenced by the expression
/// @param expr Conditional expression that glues together 0 or more labeled condition components
/// @param iParam [out] Validation argument, passed to FailValidation() on failure
/// @param bAllowEmpty If true, empty (trivially valid) expressions are accepted
void CompoundConditionNode_cl::ValidateExpression (VisTypedEngineObject_cl * pObject, const VString & expr, INT_PTR iParam, bool bAllowEmpty)
{
	if (!bAllowEmpty && expr.IsEmpty()) FailValidation(iParam, "Empty expression");

	else
	{
		ProcessResult result;

		result.mGetData = false;

		if (!ProcessExpression(pObject, expr, result)) FailValidation(iParam, "Failed to parse expression, \"%s\": %s", expr.AsChar(), result.mString.AsChar());
	}
}

/// Generates a condition node from an intermediate object
/// @param pObject Owner of any condition components referenced by the expression
/// @param expr Conditional expression that glues together 0 or more labeled condition components
/// @return Compound condition node with the given expression and fresh copies of the relevant components
CompoundConditionNode_cl * CompoundConditionNode_cl::FromObject (VisTypedEngineObject_cl * pObject, const VString & expr)
{
	CompoundConditionNode_cl * pNode = (CompoundConditionNode_cl *)Vision::Game.CreateEntity("CompoundConditionNode_cl", VisVector_cl());

	pNode->SetParentZone(pObject->GetParentZone());

	pNode->Expression = expr;

	CopyComponents(pObject, pNode, V_RUNTIME_CLASS(ConditionComponent_cl));

	return pNode;
}
--]]