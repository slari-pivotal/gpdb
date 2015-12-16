/*
 * Copyright (c) 2015 Pivotal Inc. All Rights Reserved
 *
 * ---------------------------------------------------------------------
 *
 * The dynamically linked library created from this source can be reference by
 * creating a function in psql that references it. For example,
 *
 * CREATE FUNCTION gp_dump_query(text)
 *	RETURNS text
 *	AS '$libdir/gpoptutils', 'gp_dump_query'
 *	LANGUAGE C STRICT;
 */

#include "postgres.h"
#include "funcapi.h"
#include "utils/builtins.h"
#include "nodes/print.h"
#include "gpopt/utils/nodeutils.h"
#include "rewrite/rewriteHandler.h"
#include "c.h"

extern
Query *preprocess_query_optimizer(Query *pquery, ParamListInfo boundParams);

extern
List *pg_parse_and_rewrite(const char *query_string, Oid *paramTypes, int iNumParams);

extern
List *QueryRewrite(Query *parsetree);

static
Query *parseSQL(char *szSqlText);

Datum gp_dump_query(PG_FUNCTION_ARGS);

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

PG_FUNCTION_INFO_V1(gp_dump_query);

/*
 * Parse a query given as SQL text.
 */
static Query *parseSQL(char *sqlText)
{
	Assert(sqlText);

	List *queryTree = pg_parse_and_rewrite(sqlText, NULL, 0);

	if (1 != list_length(queryTree))
	{
		elog(ERROR, "Cannot parse query. "
				"Please make sure the input contains a single valid query. \n%s", sqlText);
	}

	Query *query = (Query *) lfirst(list_head(queryTree));

	return query;
}

/*
 * Function dumping query object for a given SQL text
 */
Datum
gp_dump_query(PG_FUNCTION_ARGS)
{
	char *sql = text_to_cstring(PG_GETARG_TEXT_P(0));
	Query *query = parseSQL(sql);
	if (CMD_UTILITY == query->commandType && T_ExplainStmt == query->utilityStmt->type)
	{
		Query *queryExplained = ((ExplainStmt *)query->utilityStmt)->query;
		List *queryTree = QueryRewrite(queryExplained);
		Assert(1 == list_length(queryTree));
		query = (Query *) lfirst(list_head(queryTree));
	}
	Query *queryNormalized = preprocess_query_optimizer(query, NULL);

	StringInfoData str;
	initStringInfo(&str);
	appendStringInfo(&str,
			"(gp_dump_query - Original) \n%s(gp_dump_query - Normalized) \n%s",
			pretty_format_node_dump((const char *)nodeToString(query)),
			pretty_format_node_dump((const char *)nodeToString(queryNormalized)));

	PG_RETURN_TEXT_P(cstring_to_text(str.data));
}
