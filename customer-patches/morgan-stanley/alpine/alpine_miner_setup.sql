-- Function: alpine_miner_adaboost_changep(text, text, text, text, text[])

set search_path = public;

-- DROP FUNCTION alpine_miner_adaboost_changep(text, text, text, text, text[]);

CREATE OR REPLACE FUNCTION alpine_miner_adaboost_changep(schemaname text, tablename text, stamp text, dependcolumnq text, dependentcolumnreplaceq text, dependentcolumnstr text,  dependinfor text[])
  RETURNS double precision AS
$BODY$
DECLARE 
	rownumber float;
	i integer;
	peoso float;	
	totalpeoso float;
	temppeoso float;
	wrongnumber float;
	err float;
	maxerror float;
	ind integer :=0;
	c float :=0;
	sql text;
	sqlan text;
	tempstring text;
	result  double precision[];
BEGIN
	execute 'alter table '||schemaname||'."tp'||stamp||'"  add column "notsame" int';
	execute 'update  '||schemaname||'."tp'||stamp||'" set "notsame" = CASE WHEN '||dependentcolumnstr||' = "P('||dependentcolumnreplaceq||')"::text  THEN 0 ELSE 1 END';
	execute 'select count(*) from '||schemaname||'."tp'||stamp||'" where "notsame" =1' into wrongnumber;
	execute 'select count(*) from '||schemaname||'.'||tablename||'' into rownumber;
	err := wrongnumber/rownumber;
	execute 'select count from ( select * from (select '||dependcolumnq||', count(*) from '||schemaname||'.'||tablename||' 
	group by '||dependcolumnq||') foo order by "count" desc limit 1) AS foo' into maxerror; 
	maxerror := maxerror/rownumber;
	IF err>=maxerror
	THEN	c=0.001;
		execute 'update '||schemaname||'."pnew'||stamp||'"  set "alpine_adaboost_peoso"='||1/rownumber||',"alpine_adaboost_totalpeoso"="alpine_adaboost_id"*'||1/rownumber;
	ELSIF err=0
	THEN c=3;
		execute 'update '||schemaname||'."pnew'||stamp||'"  set "alpine_adaboost_peoso"='||1/rownumber||',"alpine_adaboost_totalpeoso"="alpine_adaboost_id"*'||1/rownumber;
	ELSE 	
		c :=ln ((1-err)/err);
		c := c/2;
		totalpeoso :=0;
		temppeoso :=0;
		i:=1;
		execute 'alter table '||schemaname||'."pnew'||stamp||'"  add column "notsame" int';
		execute 'update  '||schemaname||'."pnew'||stamp||'" set "notsame" =  '||schemaname||'."tp'||stamp||'"."notsame" from '||schemaname||'."tp'||stamp||'" where '||schemaname||'."pnew'||stamp||'"."alpine_adaboost_id" = '||schemaname||'."tp'||stamp||'"."alpine_adaboost_id"'; 
		temppeoso := temppeoso*exp (c*ind); 
		execute 'update  '||schemaname||'."pnew'||stamp||'" set  "alpine_adaboost_peoso" = "alpine_adaboost_peoso"*exp('||c||'*notsame) ';
--		execute 'select sum("alpine_adaboost_peoso") from '||schemaname||'."pnew'||stamp||'"' into totalpeoso;
--		execute 'update  '||schemaname||'."pnew'||stamp||'" set  "alpine_adaboost_peoso" = "alpine_adaboost_peoso"/'||totalpeoso;
		execute 'Drop table IF EXISTS "sp'||stamp||'"';
		execute 'Create temp table "sp'||stamp||'" as select "alpine_adaboost_id", "alpine_adaboost_peoso", sum("alpine_adaboost_peoso")over(order by "alpine_adaboost_id" ) alpine_sum_peoso  from 
 '||schemaname||'."pnew'||stamp||'"  DISTRIBUTED BY (alpine_adaboost_id)';
		execute 'update  '||schemaname||'."pnew'||stamp||'" set  "alpine_adaboost_totalpeoso" = "alpine_sum_peoso" from "sp'||stamp||'" where '||schemaname||'."pnew'||stamp||'"."alpine_adaboost_id" = "sp'||stamp||'"."alpine_adaboost_id"';
		execute 'alter table '||schemaname||'."pnew'||stamp||'"  drop column "notsame"';
	END IF ;




	  i := 2;
  
 
  sqlan:='update '||schemaname||'."p'|| stamp || '" set "C('||dependinfor[1]||')" ='||schemaname||'."p'||stamp||'"."C('||dependinfor[1]||')"+
                  '||schemaname||'."tp'||stamp||'"."C('||dependinfor[1]||')" *'||c ;
                    
  while i <= alpine_miner_get_array_count(dependinfor) loop
        sqlan:=sqlan||' , "C('||dependinfor[i]||')"='||schemaname||'."p'||stamp||'"."C('||dependinfor[i]||')"+
          '||schemaname||'."tp'||stamp||'"."C('||dependinfor[i]||')"  *'||c;
        
        i:=i+1;
   end loop;
   sqlan:=sqlan||' from  '||schemaname||'."tp'||stamp||'"  where '||schemaname||'."p'||stamp||'".alpine_adaboost_id = '||schemaname||'."tp'||stamp||'".alpine_adaboost_id';
   execute  sqlan;

	
RETURN c;

END;

 $BODY$
  LANGUAGE plpgsql VOLATILE;





-- Function: alpine_miner_adaboost_initpre(text, text, text, text[])

-- DROP FUNCTION alpine_miner_adaboost_initpre(text, text, text, text[]);

CREATE OR REPLACE FUNCTION alpine_miner_adaboost_initpre(tablename text, stamp text, dependcolumn text, infor text[],istemp boolean)
  RETURNS void AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 0;
BEGIN
	execute 'Drop table IF EXISTS "id'||stamp||'"';
	execute 'Create temp table "id'||stamp||'" as select *,row_number()over() alpine_adaboost_id from '||tablename||' DISTRIBUTED BY (alpine_adaboost_id)';
	execute 'Drop table IF EXISTS  '||tablename;
	if istemp=true
	then execute 'Create temp table '||tablename||' as select * from "id'||stamp||'" DISTRIBUTED BY (alpine_adaboost_id)';
	else
	execute 'Create  table '||tablename||' as select * from "id'||stamp||'" DISTRIBUTED BY (alpine_adaboost_id)';
	end if ;
	execute 'Drop  table IF EXISTS "to'||stamp||'"';
	


 tempstring:='update '||tablename||' set "C('||infor[1]||')"=0';

  
  for i in 2 .. alpine_miner_get_array_count(infor) loop
    tempstring := tempstring||', "C(' || infor[i] ||')"=0';
  
  end loop;

	execute tempstring;
end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;





-- Function: alpine_miner_adaboost_inittra(text, text, text, text[])

-- DROP FUNCTION alpine_miner_adaboost_inittra(text, text, text, text[]);

CREATE OR REPLACE FUNCTION alpine_miner_adaboost_inittra(schemaname text, tablename text, stamp text, dependcolumn text,dependinfor text[])
  RETURNS integer AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 1;
BEGIN
	execute 'Drop table IF EXISTS '||schemaname||'."pnew'||stamp||'"';
	execute 'Drop table IF EXISTS'||schemaname||'."dn' || stamp || '"';
	execute 'Create  table '||schemaname||'."dn' || stamp || '" 
                      as select *
                    from '||schemaname||'.'|| tablename ||' where '||dependcolumn||' is not null DISTRIBUTED RANDOMLY';
  
	execute  'select count(*)   from '||schemaname||'."dn' || stamp || '"'
	into rownumber;
	peoso := 1.0 / rownumber;

	execute 'Create  table '||schemaname||'."pnew' || stamp || '" 
                      as select *,
                    row_number()over(order by 1) alpine_adaboost_id,
                    '||peoso||' alpine_adaboost_peoso, 
                    row_number()over()*'||peoso||' alpine_adaboost_totalpeoso 
                    from '||schemaname||'."dn' || stamp || '" DISTRIBUTED BY (alpine_adaboost_id) ';


	
	classnumber:=alpine_miner_get_array_count(dependinfor);
	execute 'Drop  table IF EXISTS '||schemaname||'."tp'||stamp||'"';
	execute 'CREATE  TABLE '||schemaname||'."tp'||stamp||'" as select * from  '||schemaname||'."pnew'||stamp||'" DISTRIBUTED BY (alpine_adaboost_id)';
	
	execute 'Drop  table IF EXISTS '||schemaname||'."p'||stamp||'"';

		sql:='CREATE  TABLE '||schemaname||'."p'||stamp||'" as select *';

	while i<=classnumber	loop
			sql:=sql||',  0.0  "C('||dependinfor[i]||')"';
			i:=i+1;
			
	end loop;
	sql:=sql||' from '||schemaname||'."pnew'||stamp||'" DISTRIBUTED BY (alpine_adaboost_id)';
	
	execute sql;
	execute 'create table '||schemaname||'."s'||stamp||'" as select * from '||schemaname||'."pnew'||stamp||'" DISTRIBUTED BY (alpine_adaboost_id)';
		
RETURN rownumber;
end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;






-- Function: alpine_miner_adaboost_prere(text, text, text[])

-- DROP FUNCTION alpine_miner_adaboost_prere(text, text, text[]);

CREATE OR REPLACE FUNCTION alpine_miner_adaboost_prere(tablename text, dependcolumn text, infor text[], isnumeric int)
  RETURNS void AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	sql1 text;
	sql2 text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 0;
	err float;
BEGIN
	classnumber:= alpine_miner_get_array_count(infor);
	
	sql:= 'update '||tablename||' set  "P('||dependcolumn||')" = CASE';
	sql2 := '(';

	i:=classnumber;
	while i>1 loop
	sql2 :=sql2||'  "C('||infor[i]||')" ,';
	
	i:=i-1;
	end loop;
	sql2:=sql2||' "C('||infor[1]||')")';
	for i in 1..alpine_miner_get_array_count(infor) loop
		sql := sql||' WHEN "C('||infor[i]||')"=greatest'||sql2||' THEN ';
		if isnumeric = 1 then
			sql := sql || infor[i];
		else
			sql := sql||''''||infor[i]||'''';
		end if;
	end loop;
	sql := sql||' END ';
	execute sql;


end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;


-- Function: alpine_miner_adaboost_prestep(text, text, text, double precision, text[])

-- DROP FUNCTION alpine_miner_adaboost_prestep(text, text, text, double precision, text[]);

CREATE OR REPLACE FUNCTION alpine_miner_adaboost_prestep(tablename text, temptable text, dependcolumn text, c double precision, infor text[])
  RETURNS double precision AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	sql1 text;
	sql2 text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 0;
	err float;
	
BEGIN	
	sql:='update ' || tablename || '  set "C(' ||
                      infor[1] || ')"= ' || tablename || '."C(' || infor[1] ||
                      ')"+ '||temptable||'."C('||infor[1]||')"*'||c;
			for i in 2..alpine_miner_get_array_count(infor) loop
			sql:=sql||' ,"C('||infor[i]||')"= '||tablename||'."C('||infor[i]||')"+ 
				'||temptable||'."C('||infor[i]||')"*'||c ;
					
	end loop;

		sql:=sql||'from '||temptable||'  where '||tablename||'.alpine_adaboost_id = '||temptable||'.alpine_adaboost_id';
	execute sql;
RETURN c;
end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;




-- Function: alpine_miner_adaboost_sample(text, text, text)

-- DROP FUNCTION alpine_miner_adaboost_sample(text, text, text);

CREATE OR REPLACE FUNCTION  alpine_miner_adaboost_sample(schemaname text, tablename text, stamp text, partsize integer)
  RETURNS text AS
$BODY$
DECLARE 
	rownumber integer;
	randomnumber float;
	myrecord record;
	partnumber integer;
	--partsize   integer;
	tempstring text;
	splitpeoso double precision[];
	maxpeoso   double precision;
	i          integer;
BEGIN
	execute 'select count(*) from '||schemaname||'.'||tablename into rownumber;
	execute ' select max(alpine_adaboost_totalpeoso)  from '||schemaname||'.'||tablename into maxpeoso;
	if partsize>= rownumber
	then 
		partnumber:=1;
	else 
		if mod(rownumber ,partsize)=0
		then
			partnumber:= rownumber/partsize;
		else 
			partnumber:=trunc(rownumber/partsize)+1;
		end if;
	end if;
 	execute 'Drop table IF EXISTS '||schemaname||'."s'||stamp||'"';
	execute 'Drop table IF EXISTS "r'||stamp||'"';
	execute 'create temp table "r'||stamp||'" as select '||maxpeoso||'*random() as alpine_miner_adaboost_r from '||schemaname||'.'||tablename||' order by alpine_miner_adaboost_r DISTRIBUTED by (alpine_miner_adaboost_r)';
	if partnumber=1 
	then
		execute 'create table '||schemaname||'."s'||stamp||'" as select * from '||schemaname||'.'||tablename||' join  "r'||stamp||'" on 
		'||schemaname||'.'||tablename||'.alpine_adaboost_totalpeoso >= "r'||stamp||'".alpine_miner_adaboost_r  and '||schemaname||'.'||tablename||'.alpine_adaboost_peoso > 
		('||schemaname||'.'||tablename||'.alpine_adaboost_totalpeoso-"r'||stamp||'".alpine_miner_adaboost_r ) DISTRIBUTED BY (alpine_adaboost_id)';
	else 
		--partsize:=trunc(rownumber*percent);
		tempstring:=' select alpine_adaboost_totalpeoso as peoso from '||schemaname||'.'||tablename||' where mod(alpine_adaboost_id,'||partsize||')=0 order by peoso';

		i:=1;
		splitpeoso[i]:=0;
		for myrecord in execute tempstring loop
			i:=i+1;
			splitpeoso[i]:=myrecord.peoso;
		 
		end loop;

		
		if splitpeoso[i]!=maxpeoso
		then
			i:=i+1;
			splitpeoso[i]:=maxpeoso;
	 
		end if;
		i:=1;
		tempstring:='create table '||schemaname||'."s'||stamp||'" as select * from  ( select * from '||schemaname||'.'||tablename||' 
			where alpine_adaboost_totalpeoso>'||splitpeoso[i]||' and  alpine_adaboost_totalpeoso<='||splitpeoso[i+1]||') as foo'||i||' join (select * from "r'||stamp||'" where alpine_miner_adaboost_r 
			>'||splitpeoso[i]||' and  alpine_miner_adaboost_r<='||splitpeoso[i+1]||') as foor'||i||' on foo'||i||'.alpine_adaboost_totalpeoso >=foor'||i||'.alpine_miner_adaboost_r and foo'||i||'.alpine_adaboost_peoso > 
		(foo'||i||'.alpine_adaboost_totalpeoso-foor'||i||'.alpine_miner_adaboost_r) ';
		tempstring:=tempstring||' DISTRIBUTED by (alpine_adaboost_id)';
		execute tempstring;
		 
 		for i in 2..partnumber loop
			tempstring:= '  insert into  '||schemaname||'."s'||stamp||'"   select * from ( select * from '||schemaname||'.'||tablename||' 
  			where alpine_adaboost_totalpeoso>'||splitpeoso[i]||' and  alpine_adaboost_totalpeoso<='||splitpeoso[i+1]||') as foo'||i||' join (select * from "r'||stamp||'" where alpine_miner_adaboost_r 
  			>'||splitpeoso[i]||' and  alpine_miner_adaboost_r<='||splitpeoso[i+1]||') as foor'||i||' on foo'||i||'.alpine_adaboost_totalpeoso >=foor'||i||'.alpine_miner_adaboost_r and foo'||i||'.alpine_adaboost_peoso > 
 			(foo'||i||'.alpine_adaboost_totalpeoso-foor'||i||'.alpine_miner_adaboost_r) ';
		 
			execute tempstring;
		end loop;
 	end if;
	tempstring = 's'||stamp;
	RETURN tempstring; 
end;
 $BODY$
  LANGUAGE plpgsql VOLATILE;



  CREATE OR REPLACE FUNCTION alpine_miner_contains (myarray text[], element text)
returns integer
as $$
begin
	for i in 1..alpine_miner_get_array_count(myarray) loop
		if myarray[i] = element then
			return 1;
		end if;
	end loop;
	return 0;
end;
$$ LANGUAGE plpgsql ;

CREATE or replace FUNCTION  alpine_miner_instr(varchar, varchar) RETURNS integer AS $$
DECLARE
    pos integer;
BEGIN
    pos:= alpine_miner_instr($1, $2, 1);
    RETURN pos;
END;
$$ LANGUAGE plpgsql ;


CREATE or replace FUNCTION  alpine_miner_instr(string varchar, string_to_search varchar, beg_index integer)
RETURNS integer AS $$
DECLARE
    pos integer DEFAULT 0;
    temp_str varchar;
    beg integer;
    length integer;
    ss_length integer;
BEGIN
    IF beg_index > 0 THEN
        temp_str := substring(string FROM beg_index);
        pos := position(string_to_search IN temp_str);

        IF pos = 0 THEN
            RETURN 0;
        ELSE
            RETURN pos + beg_index - 1;
        END IF;
    ELSE
        ss_length := char_length(string_to_search);
        length := char_length(string);
        beg := length + beg_index - ss_length + 2;

        WHILE beg > 0 LOOP
            temp_str := substring(string FROM beg FOR ss_length);
            pos := position(string_to_search IN temp_str);

            IF pos > 0 THEN
                RETURN beg;
            END IF;

            beg := beg - 1;
        END LOOP;

        RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;

create or replace function alpine_miner_get_array_count(myarray text[])
returns integer as $$
declare
	array_dims_result text;
	begin_pos int := 1;
	end_pos int := 1;
	temp_str text;
begin
	select array_dims(myarray) into array_dims_result;
	begin_pos := alpine_miner_instr(array_dims_result, ':')+1;
	end_pos := alpine_miner_instr(array_dims_result, ']') ;
	temp_str := substring(array_dims_result from begin_pos for (end_pos - begin_pos));
	return to_number(temp_str,'99999999999999999999');
end;
$$ language plpgsql;



create or replace function alpine_miner_get_array_countI(myarray integer[])
returns integer as $$
declare
	array_dims_result text;
	begin_pos int := 1;
	end_pos int := 1;
	temp_str text;
begin
	
	select array_dims(myarray) into array_dims_result;
	begin_pos := alpine_miner_instr(array_dims_result, ':')+1;
	end_pos := alpine_miner_instr(array_dims_result, ']') ;
	temp_str := substring(array_dims_result from begin_pos for (end_pos - begin_pos));
	return to_number(temp_str,'99999999999999999999');
end;
$$ language plpgsql;



create or replace function alpine_miner_get_array_countF(myarray float[])
returns integer as $$
declare
	array_dims_result text;
	begin_pos int := 1;
	end_pos int := 1;
	temp_str text;
begin
	
	select array_dims(myarray) into array_dims_result;
	begin_pos := alpine_miner_instr(array_dims_result, ':')+1;
	end_pos := alpine_miner_instr(array_dims_result, ']') ;
	temp_str := substring(array_dims_result from begin_pos for (end_pos - begin_pos));
	return to_number(temp_str,'99999999999999999999');
end;
$$ language plpgsql;


  CREATE OR REPLACE FUNCTION alpine_miner_split 
(
    p_list text,
    p_del text 
) returns text[]
as $$
declare
    l_idx   integer;
    l_list   text := p_list;
    l_value    text;
    result text[];
    result_count int := 0;
begin
    loop
        l_idx := alpine_miner_instr(l_list,p_del);
        result_count := result_count + 1;
        if l_idx > 0 then
            result[result_count]:= (substr(l_list,1,l_idx-1));
            l_list := substr(l_list,l_idx+length(p_del));
        else
            result[result_count] := l_list;
            exit;
        end if;
    end loop;
    return result;
end;
$$ LANGUAGE plpgsql ;

  CREATE OR REPLACE FUNCTION alpine_miner_ar_predict (text_attribute integer, attribute_double float[], attribute_text text[], positive text, ar text)-- ar clob)
returns text
as $$
declare
	--sqlstr text := '';
	i int := 0;
	result text := null;
	result_array text[];
	premise_conclusion_array text[];
	premise_array text[];
	conclusion_array text[];
	ar_array text[];
	--arribute_length integer := 0;
	conclusion_ok integer := 1;
	premise_str text;
	conclusion_str text;
	result_array_count integer := 1;
BEGIN
		if ar = '' or ar is null then
			return null;
		end if;
		ar_array := alpine_miner_split(ar, ';');
		for i in 1..alpine_miner_get_array_count(ar_array) loop
			premise_conclusion_array := alpine_miner_split(ar_array[i], ':');
			premise_str := premise_conclusion_array[1];
			premise_array := alpine_miner_split(premise_str, '|');
			conclusion_str := premise_conclusion_array[2];
			conclusion_array := alpine_miner_split(conclusion_str, '|');
			conclusion_ok := 1;
				if(text_attribute = 1) then
					if attribute_text[TO_NUMBER(conclusion_array[2],'99999999999999999999')] = positive then
						continue;
					end if;
				else
					if attribute_double[TO_NUMBER(conclusion_array[2],'99999999999999999999')] = positive then
						continue;
					end if;
				end if;

			for j in 1.. alpine_miner_get_array_count(premise_array) loop
				if(text_attribute = 1) then
					if attribute_text[TO_NUMBER(premise_array[j],'99999999999999999999')] !=  positive then
						conclusion_ok := 0;
						exit;
					end if;
				else
					if attribute_double[TO_NUMBER(premise_array[j],'99999999999999999999')] !=  positive then
						conclusion_ok := 0;
						exit;
					end if;
				end if;
			end loop;
			if conclusion_ok = 1 then
				if result_array is null or alpine_miner_contains(result_array, conclusion_array[1])  = 0 then
					result_array[result_array_count] := conclusion_array[1];
					result_array_count := result_array_count + 1;
					if result is not null then
						result := result||',';
					else
						result := '';
					end if;
					result := result || conclusion_array[1];
				end if;
			end if;
		end loop;
	RETURN result;
END;
$$ LANGUAGE plpgsql ;
CREATE OR REPLACE FUNCTION alpine_miner_corr_accum(state DOUBLE PRECISION[], x DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_corr_combine(state1 DOUBLE PRECISION[], state2 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_corr_final(state1 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

DROP AGGREGATE IF EXISTS alpine_miner_corr(DOUBLE PRECISION[]);
CREATE AGGREGATE alpine_miner_corr(DOUBLE PRECISION[]) (
    SFUNC=alpine_miner_corr_accum,
    STYPE=float8[],
    prefunc=alpine_miner_corr_combine,
    INITCOND='{0}',
    FINALFUNC=alpine_miner_corr_final
);


CREATE OR REPLACE FUNCTION alpine_miner_covar_sam_accum(state DOUBLE PRECISION[], x DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_covar_sam_combine(state1 DOUBLE PRECISION[], state2 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_covar_sam_final(state1 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

DROP AGGREGATE IF EXISTS alpine_miner_covar_sam(DOUBLE PRECISION[]);
CREATE AGGREGATE alpine_miner_covar_sam(DOUBLE PRECISION[]) (
    SFUNC=alpine_miner_covar_sam_accum,
    STYPE=float8[],
    prefunc=alpine_miner_covar_sam_combine,
    INITCOND='{0}',
    FINALFUNC=alpine_miner_covar_sam_final
);



CREATE OR REPLACE FUNCTION alpine_miner_covar_accum(state DOUBLE PRECISION[], x DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_covar_combine(state1 DOUBLE PRECISION[], state2 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_covar_final(state1 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

DROP AGGREGATE IF EXISTS alpine_miner_covar(DOUBLE PRECISION[]);
CREATE AGGREGATE alpine_miner_covar(DOUBLE PRECISION[]) (
    SFUNC=alpine_miner_covar_accum,
    STYPE=float8[],
    prefunc=alpine_miner_covar_combine,
    INITCOND='{0}',
    FINALFUNC=alpine_miner_covar_final
);


create or replace function alpine_miner_get_dbtype() 
returns text as
$$
begin
        return 'Greenplum';
end;
$$
language 'plpgsql';


create or replace function getAMVersion() 
returns text as
$$
begin
        return 'Alpine Data Labs Release 5.0';
end;
$$
language 'plpgsql';


CREATE OR REPLACE FUNCTION alpine_miner_array_avg(arraydata double precision[], arraysize bigint)
  RETURNS double precision[] AS
$BODY$
DECLARE 
	i integer;
	newarraydata double precision[];
BEGIN
	i:=1;
	while i <= alpine_miner_get_array_count(arraydata) loop
	newarraydata[i]:=arraydata[i] /arraysize;
	i:=i+1;
	end loop;
RETURN newarraydata;

END;

$BODY$
LANGUAGE plpgsql VOLATILE;
  
  
CREATE OR REPLACE FUNCTION alpine_miner_em_getp(columnarray double precision[], mu double precision[],sigma double precision[],
alpha double precision)
RETURNS double precision
AS 'alpine_miner','alpine_miner_em_getp'
LANGUAGE C
IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION alpine_miner_em_getmaxsub(firstarray double precision[], secondarray double precision[])
RETURNS double precision
AS 'alpine_miner','alpine_miner_em_getmaxsub'
LANGUAGE C
IMMUTABLE STRICT;




-- Function: alpine_miner_em_train(text, text[], integer, integer, integer, double precision, text)

-- DROP FUNCTION alpine_miner_em_train(text, text[], integer, integer, integer, double precision, text);

CREATE OR REPLACE FUNCTION alpine_miner_em_train(tablename text, columnname text[], clusternumber integer, clustersize integer, maxiteration integer, epsilon double precision, temptable text,sigmas double precision[])
  RETURNS double precision[] AS
$BODY$
DECLARE 
	sql text;
	alpha double precision[];
	mu  double precision[];
	sigma double precision[];
	prealpha double precision[];
	premu  double precision[];
	presigma double precision[];
	maxsubalpha double precision;
	maxsubmu double precision;
	maxsubsigma double precision;
	maxsubvalue double precision;
	test double precision[];
	columnsize integer;
	tempmu text;
	tempsigma text;
	tempalpha text;
	sum text;
	tempiteration integer;
	stop integer;
	i integer;
	j integer;
	k integer;
	myrecord record;
BEGIN
	
	columnsize:=alpine_miner_get_array_count(columnname);
	sql:=' select alpine_miner_array_avg(sum(arraydata),sum(1)) as a from ( select array['||array_to_string(columnname,',')||'] as arraydata,mod( row_number() over (order by random()),'||clusternumber||' ) as clusterid from '||tablename||'  
	where '||array_to_string(columnname,' is not null and ')||' is not null limit   '||clusternumber||'*'||clustersize ||') as foo group by clusterid ';
	 
	i:=1;
	k:=1;
	j:=0;
	for myrecord in execute sql loop
		if j=0
		then 
		mu:= myrecord.a;
		sum:='(alpine_miner_em_p'||k;
		j:=1;
		else
		mu:=array_cat(mu,myrecord.a);
		sum:=sum||'+alpine_miner_em_p'||k;
		end if;
		alpha[k]:=1.0/clusternumber;
		k:=k+1;
	end loop;
	sum:=sum||') as alpine_miner_em_sum ';
	for i in 1.. columnsize*clusternumber loop
		sigma[i]:=sigmas[i];
	end loop;	
	sql:=' create temp table '||temptable||' as select * , '||sum||' from ( select  *';
	for i in 1..  clusternumber loop
		 
		sql:=sql||' , alpine_miner_em_getp(array['||array_to_string(columnname,',')||'] , array['||array_to_string(mu[((i-1)*columnsize+1):(i*columnsize)],',')||'] , 
		array['||array_to_string(sigma[((i-1)*columnsize+1):(i*columnsize)],',')||'] ,'||alpha[i]||' ) as alpine_miner_em_p'||i ;
	end loop;		
	sql:=sql||'   from '||tablename||') as foo';
	 
	execute sql;
	
	sql:=' update  '||temptable||' set alpine_miner_em_p1=(case when alpine_miner_em_p1<1e-22 and alpine_miner_em_sum<1e-20 then '||1.0/clusternumber||' else alpine_miner_em_p1 end)';
	for i in 2..  clusternumber loop
		sql:=sql||',alpine_miner_em_p'||i||'=(case when alpine_miner_em_p'||i||'<1e-22 and alpine_miner_em_sum<1e-20 then '||1.0/clusternumber||' else alpine_miner_em_p'||i||' end)';
	end loop;
	execute sql;

	sql:=' update  '||temptable||' set alpine_miner_em_sum=alpine_miner_em_p1';
	for i in 2..  clusternumber loop
		sql:=sql||'+alpine_miner_em_p'||i;
	end loop;
	execute sql;
	
	tempiteration:=2;
	stop:=0;
	while stop=0 and tempiteration<=maxiteration loop

	prealpha:=alpha;
	premu:=mu;
	presigma:=sigma;
	for i in 1..  clusternumber loop
		if i=1
		then 
		tempalpha:=' array[avg(alpine_miner_em_p1/alpine_miner_em_sum)';

		for j in 1 ..columnsize loop
			if j=1 then
			tempmu:=' array[sum('||columnname[j]||'*alpine_miner_em_p'||i||'/alpine_miner_em_sum)/sum(alpine_miner_em_p'||i||'/alpine_miner_em_sum)';
			else
			tempmu:=tempmu||',sum('||columnname[j]||'*alpine_miner_em_p'||i||'/alpine_miner_em_sum)/sum(alpine_miner_em_p'||i||'/alpine_miner_em_sum)';
			end if;
		end loop;
		else
		tempalpha:=tempalpha||',avg(alpine_miner_em_p'||i||'/alpine_miner_em_sum)';
		for j in 1 ..columnsize loop
			 
			tempmu:=tempmu||',sum('||columnname[j]||'*alpine_miner_em_p'||i||'/alpine_miner_em_sum)/sum(alpine_miner_em_p'||i||'/alpine_miner_em_sum)';
			 
		end loop;
		
		end if;
	end loop;
	tempalpha:=tempalpha||'] ';
	tempmu:=tempmu||']';
  	sql:=' select  '||tempalpha||' as alpha ,'||tempmu||' as mu from '||temptable;
  	for myrecord in execute sql loop
  	alpha:=myrecord.alpha;
  	mu:=myrecord.mu;
  	end loop;
  	k:=1;
  	for i in 1..  clusternumber loop
  		for j in 1 ..columnsize loop
  			if i=1
  			then 
  				if j=1 then
  				 
  				tempsigma:=' array[sum(('||columnname[j]||'- '||mu[k]||')*('||columnname[j]||'- '||mu[k]||')*alpine_miner_em_p'||i||'/alpine_miner_em_sum)/sum(alpine_miner_em_p'||i||'/alpine_miner_em_sum)';
  				else
  				 
  				tempsigma:=tempsigma||',sum(('||columnname[j]||'- '||mu[k]||')*('||columnname[j]||'- '||mu[k]||')*alpine_miner_em_p'||i||'/alpine_miner_em_sum)/sum(alpine_miner_em_p'||i||'/alpine_miner_em_sum)';
  				end if;
  			
  		
  			else
  			 
  			tempsigma:=tempsigma||',sum(('||columnname[j]||'- '||mu[k]||')*('||columnname[j]||'- '||mu[k]||')*alpine_miner_em_p'||i||'/alpine_miner_em_sum)/sum(alpine_miner_em_p'||i||'/alpine_miner_em_sum)';  		
  			end if;
  			k:=k+1;
  		end loop;
  	end loop;
	tempsigma:=tempsigma||'] ';
  	sql:=' select  '||tempsigma||' as sigma  from '||temptable;
 	for myrecord in execute sql loop
  	sigma:=myrecord.sigma;
  	
  	end loop;

	maxsubalpha:=alpine_miner_em_getmaxsub(prealpha,alpha);
  	maxsubmu:=alpine_miner_em_getmaxsub(premu,mu);
	maxsubsigma:=alpine_miner_em_getmaxsub(presigma,sigma);

	if maxsubalpha>maxsubmu and maxsubalpha>maxsubsigma
	then maxsubvalue:=maxsubalpha;
	else 
	if maxsubmu>maxsubalpha and maxsubmu>maxsubsigma
	then maxsubvalue:=maxsubmu;
	else 
	if maxsubsigma>maxsubalpha and maxsubsigma>maxsubmu
	then maxsubvalue:=maxsubsigma;
	end if;
	end if;
	end if;
	if epsilon>maxsubvalue
	then
	stop:=1;
	end if;
	tempiteration:=tempiteration+1;
	end loop;


	
RETURN array_cat(array_cat(alpha,mu),sigma);

END;

 $BODY$
  LANGUAGE plpgsql VOLATILE;
 
CREATE OR REPLACE FUNCTION  alpine_miner_em_predict(outputtable text,predicttable text,columnname text[],modelinfo double precision[],appendonly text,endingstring text,clusternumber integer)
 RETURNS integer AS
$BODY$
DECLARE
	sql 	text;
	alpha 	double precision[];
	mu 	double precision[];
	sigma	double precision[];
	columnsize integer;
	sum 	text;
	max 	text;
	casewhen text;
	updatesql text;
	resultsql text;
	i 	integer;
	j	integer;
	k	integer;

BEGIN
	
	columnsize:=alpine_miner_get_array_count(columnname);


	for i in 1..clusternumber loop
		alpha[i]:=modelinfo[i];
		for j in 1..columnsize loop
			mu[(i-1)*columnsize+j]:=modelinfo[clusternumber+(i-1)*columnsize+j];
			sigma[(i-1)*columnsize+j]:=modelinfo[clusternumber+clusternumber*columnsize+(i-1)*columnsize+j];
		end loop;
	end loop;
	
	
	for i in 1..clusternumber loop
		if i = 1
		then
			max:='greatest("C(alpine_miner_emClust'||i||')"';
			sum:='("C(alpine_miner_emClust'||i||')"';
			updatesql:=' set "C(alpine_miner_emClust'||i||')"="C(alpine_miner_emClust'||i||')"/alpine_em_sum ';
		else 
			max:=max||',"C(alpine_miner_emClust'||i||')"';
			sum:=sum||'+"C(alpine_miner_emClust'||i||')"';
			updatesql:=updatesql||',"C(alpine_miner_emClust'||i||')"="C(alpine_miner_emClust'||i||')"/alpine_em_sum ';
		end if;
	end loop;

	
	
	max:=max||')';
	sum:=sum||') as alpine_em_sum';
	casewhen:=' case ';
	for i in 1..clusternumber loop
		casewhen:=casewhen||' when "C(alpine_miner_emClust'||i||')"='||max||' then  '||i||' ';

	end loop;
	casewhen := casewhen ||' end ';
	sql:=' create  table '||outputtable||appendonly||' as select * , '||sum||', '||casewhen||' alpine_em_cluster from ( select  *';
	for i in 1..  clusternumber loop
		 
		sql:=sql||' , alpine_miner_em_getp(array['||array_to_string(columnname,',')||'] , array['||array_to_string(mu[((i-1)*columnsize+1):(i*columnsize)],',')||'] , 
		array['||array_to_string(sigma[((i-1)*columnsize+1):(i*columnsize)],',')||'] ,'||alpha[i]||' ) as "C(alpine_miner_emClust'||i||')"' ;
	end loop;		
	sql:=sql||'   from '||predicttable||') as foo'||endingstring;
	 
	 execute sql;
	 sql:=' update '||outputtable|| updatesql;
	 execute sql;
	 sql:=' alter table '||outputtable||' drop column alpine_em_sum';
	 execute sql;
 return 1;
end;
$BODY$
LANGUAGE plpgsql VOLATILE;CREATE OR REPLACE FUNCTION alpine_miner_generate_random_table(t text, rowCount bigint) RETURNS integer AS $$
DECLARE 
	--rand bigint;
	--rand double precision;
	count bigint := 1;
BEGIN
	WHILE count <= rowCount LOOP
		--select trunc(random()*rowCount) into rand;
		--select random() into rand;
		execute 'insert into '||t||' select '||count||','||random();
		count := count + 1;
	END LOOP;
return 1;
END;
$$ LANGUAGE plpgsql VOLATILE;
-- Function: alpine_miner_getdistribution(text, text)

-- DROP FUNCTION alpine_miner_getdistribution(text, text);

CREATE OR REPLACE FUNCTION alpine_miner_getdistribution(tablename text, schemaname text)
  RETURNS smallint[] AS
$BODY$

DECLARE
	 result smallint[];
BEGIN
execute 'select attrnums from gp_distribution_policy where localoid in (select relid from pg_stat_user_tables where relname='''||tablename||''' and schemaname like '''||schemaname||''')' into result;


RETURN result;
 
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE;
CREATE OR REPLACE FUNCTION alpine_miner_kmeans_c_array_array(table_name text, table_name_withoutschema text, column_name text[], column_array_length int[], column_number integer, id text, tempid text, clustername text, k integer, max_run integer, max_iter integer, distance integer)
  RETURNS double precision[] AS
$BODY$
DECLARE
    run integer:=1;
    none_stable integer;
    tmp_res_1 varchar(50):='';
    tmp_res_2 varchar(50):='';
    tmp_res_3 varchar(50):='';
    tmp_res_4 varchar(50):='';
    result1 varchar(50):='';
    column_array text:='';
    avg_array text:='';
    x_array text:='';
    i integer := 0;
    j integer := 0;
    l integer := 0;
    m integer := 0;
    n integer := 0;
    sql text:='';
    sql1 text:='';
    temptablename text:='';
    column_all text:='';
    comp_sql text:='';
    result_sql text:='';
    sampleid integer;
    sample_array text:='';
    data_array text:='';
    roww record;
    init_array text:='';
    init_array1 text:='';
    sample_array3 text[];
    sample_array1 text:='';
    sample_array2 text:='';
    column_new text:='';
     xx_array text;
     comp_sql_new text:='';
     alpine_id text:='';
     resultarray float[2];
    tempsum float;
    nullflag smallint:=0;
    column_array_sum integer:= 0;
    column_array_index integer:= 0;
    first boolean := true;
    temp_text text := '';
    temp_index integer := 0;
  
BEGIN

i := 1;
while i <= column_number loop
	if column_array_length[i] = 0 then
		column_array_sum := column_array_sum + 1;
	else
		column_array_sum := column_array_sum + column_array_length[i];
	end if ;
	i := i+ 1;
end loop;

temptablename:=table_name_withoutschema;

if id='null'
then 
sql:= 'create temp table '||temptablename||'copy as(select *,row_number() over () '||tempid||' from '||table_name||' where ';
alpine_id:=tempid;
else
sql:= 'create temp table '||temptablename||'copy as(select * from '||table_name||' where ';
alpine_id:=id;
end if;

i := 1;
while i < (column_number) loop
	sql:=sql||' "'||column_name[i]||'" is not null and ';
	i := i + 1;	
end loop;
sql:=sql||' "'||column_name[i]||'" is not null';


sql:=sql||') distributed by('||alpine_id||')';

--raise notice '0 asdf sql:%',sql;
execute sql;

column_array := column_name[1];

i := 2;
while i < (column_number + 1) loop
	column_array := column_array||',"'||column_name[i]||'"';
	i := i + 1;
end loop;


-------------------------------
sql:='create temp table '||temptablename||'init as select tablek1.seq sample_id,0::smallint as stable,';
i := 1;
while i<(k + 1) loop
	sql:=sql||'k'||i||',';
	i := i + 1;
	end loop;
	sql:=sql||'0::integer as iter from';
i := 1;
----raise notice 'k:%, column_number:%', k, column_number;
 while i<(k + 1) loop
sql:=sql||'(select array[';
	 j := 1;
	while j<=(column_number) loop
	  --sql:=sql||'"'||column_name[j]||'",';
          if j != 1 then
             sql:=sql||',';
          end if;
          if column_array_length[j] < 1 then
	  	sql:=sql||'"'||column_name[j]||'"';
          else
                l := 1;
                while l <= column_array_length[j] loop
          		if l != 1 then
		             sql:=sql||',';
		        end if;
                    sql:=sql||'"'||column_name[j]||'"['||l||']';
                    l := l + 1;
                end loop;
          end if;
	  j := j + 1;
	end loop;
	sql:=sql||'] k'||i||',';
	if i=1 then sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq'; 
	else sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq inner join ';end if;
	end if;
	i := i + 1;
 end loop;
sql:=sql||'  distributed by (sample_id) ';
--raise notice '1 asdf sql:%',sql;
execute sql;

sql:='create temp table '||temptablename||'_random_new as select sample_id,stable,';
i := 1;
column_array_index := 1;
temp_index := 0;
first := true;
while i<column_number+1 loop
	sql:=sql||'array[';
	j:=1;
	first := true;
	column_array_index := temp_index + 1;
	if column_array_length[i] < 1 then
	while j<=k loop
		if first is true then
			first := false;
		else
			sql := sql||',';
		end if;
		sql:=sql||'k'||j||'['||column_array_index||']'; 
	j := j + 1;
	end loop;
	else
		l := 1;
		while l <= column_array_length[i] loop
		  j := 1;
		  while j<=k loop
			if first is true then
				first := false;
			else
				sql := sql||',';
			end if;
			sql:=sql||'k'||j||'['||column_array_index||']';
		  j := j + 1;
		  end loop;
			l := l + 1;
			column_array_index := column_array_index + 1;
		end loop;
	end if;
	if column_array_length[i] < 1 then
		temp_index := temp_index + 1;
	else
		temp_index := temp_index + column_array_length[i];
	end if;
	sql:=sql||']::float[] "'||column_name[i]||'",';
	i := i + 1;
end loop;
	sql:=sql||' iter from '||temptablename||'init distributed by (sample_id)';
--raise notice '2 asdf sql:%',sql;
execute sql;
-------------------------------
------generate random table start------

i := 1;
first := true;
sample_array1:=sample_array1||'array[';
while i<(k + 1) loop
	 j := 1;
	while j<(column_number+1) loop
--	if i=k and j=column_number then
--	 sample_array1:=sample_array1||'y."'||column_name[j]||'"['||i||']]::float[]'; 
--	 else
--	 sample_array1:=sample_array1||'y."'||column_name[j]||'"['||i||'],';
--	  end if;
	if column_array_length[j] < 1 then
		if first is true then
			first := false;
		else
			sample_array1 := sample_array1||',';
		end if;
		sample_array1:=sample_array1||'y."'||column_name[j]||'"['||i||']';--     'k'||j||'['||column_array_index||']'; 
	else
		l := 1;
		column_array_index := i;
		while l <= column_array_length[j] loop
			if first is true then
				first := false;
			else
				sample_array1 := sample_array1||',';
			end if;
			sample_array1:=sample_array1||'y."'||column_name[j]||'"['||column_array_index||']';
			l := l + 1;
			column_array_index := column_array_index + k;
		end loop;
	end if;
	if i=k and j=column_number then
		sample_array1:=sample_array1||']::float[]';
	end if;
	  j := j + 1;
	end loop;
	i := i + 1;
 end loop;
 
----raise notice '----sample_array1 sql:%',sample_array1;
---------generate random table end-------------

---------Adjust stable start--------------
while run<=max_iter  loop
tmp_res_1:='tmp_res_1'||run::varchar;
tmp_res_2:='tmp_res_2'||run::varchar;
tmp_res_3:='tmp_res_3'||run::varchar;
tmp_res_4:='tmp_res_4'||run::varchar;
i := 1;
first = true;
avg_array := '';
while i < (column_number + 1) loop
	if first is true then
		first := false;
	else
		avg_array := avg_array||',';
	end if;
	if column_array_length[i] < 1 then
		avg_array := avg_array||'avg("'||column_name[i]||'")::numeric(25,10)'; 
	else
		l := 1;
		avg_array := avg_array||'array[';
		while l <= column_array_length[i] loop
			if l != 1 then
				avg_array := avg_array||',';
			end if;
			avg_array := avg_array||'avg("'||column_name[i]||'"['||l||'])::numeric(25,10)';
			l := l + 1;
		end loop;
		avg_array := avg_array||']::numeric(25,10)[]';
	end if;
	avg_array := avg_array||' "'||column_name[i]||'"';
	--avg_array := avg_array||' "'||column_name[i]||'"';
        --avg_array := avg_array||',avg("'||column_name[i]||'")::numeric(25,10) "'||column_name[i]||'"';
	i := i + 1;
end loop;


------------------

data_array:='array[';
i:=1;
while i<=column_number loop
if (i != 1) then
	data_array := data_array||',';
end if;
--data_array:=data_array||'x."'||column_name[i]||'"';
	if column_array_length[i] < 1 then
		data_array:=data_array||'x."'||column_name[i]||'"'; 
	else
		l := 1;
		while l <= column_array_length[i] loop
			if l != 1 then
				data_array:=data_array||',';
			end if;
			--avg_array := avg_array||'avg("'||column_name[i]||'"['||l||'])::numeric(25,10)';
			data_array:=data_array||'x."'||column_name[i]||'"['||l||']';
			l := l + 1;
		end loop;
	end if;
i:=i+1;
end loop;
data_array:=data_array||']';
--data_array:=data_array||'x."'||column_name[i]||'"]';

---------------
sql:='create temp table '||temptablename||tmp_res_2||' (sample_id integer,'||alpine_id||' character varying,cluster_id integer) distributed by ('||alpine_id||')';
--raise notice '3 asdf sql:%',sql;
execute sql;
i:=1;
sql:='select sample_id::smallint,'||sample_array1||'::float[] from '||temptablename||'_random_new y where stable=0 order by sample_id';
-- --raise notice 'sql:%',sql;
--raise notice '4 asdf sql:%',sql;
     for roww in execute sql loop
	 sample_array3=roww.array;
	 sampleid=roww.sample_id;
	 sample_array2:='';
	j:=1;
	while j<column_array_sum*k loop
	sample_array2:=sample_array2||sample_array3[j]||',';
	j:=j+1;
	end loop;
	sample_array2:=sample_array2||sample_array3[j];
	sample_array2:='array['||sample_array2||']';
	sql1:='insert into '||temptablename||tmp_res_2||' select '||sampleid||'::smallint,'||alpine_id||',alpine_miner_kmeans_distance_loop('||sample_array2;
	sql1:=sql1||'::float[],'||data_array||'::float[],'||k||','||distance||')as cluster_id from '||temptablename||'copy x';
	  ----raise notice 'sqll:%',sql1;
	--raise notice '5 asdf sql:%',sql1;
	 execute sql1;
	 i:=i+1;
     end loop;
---------------


--------tmp_res_2 caculate each point in random table's distance to each point in date table and get each point in date table should belong to which cluster----------
/*sql:='drop table if exists '||temptablename||tmp_res_2||';create temp table '||temptablename||tmp_res_2||' as (select 
	sample_id,'||id||',alpine_miner_kmeans_distance_loop('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as cluster_id
from '||temptablename||'copy x inner join '||temptablename||'_random_new y on y.stable=0) distributed by (sample_id,'||id||',cluster_id)';

execute sql;*/


-----tmp_res_1 caculate unstable cluster---
sql:='drop table if exists '||temptablename||tmp_res_1||'; create temp table '||temptablename||tmp_res_1||'   as
(
select 
	sample_id,
 	cluster_id,
	'||avg_array||'
from '||temptablename||tmp_res_2||'
x,'||temptablename||'copy y
where x.'||alpine_id||'=y.'||alpine_id||'
 group by 1,2
)distributed by(sample_id,cluster_id)
 ;
 ';

--raise notice '6 asdf sql:%',sql;
execute sql;
 
--raise info '------------1--------------'; 


sql:='drop table if exists '||temptablename||'temp;create temp table '||temptablename||'temp as select tablek1.sample_id,0::smallint as stable,';
i := 1;
 while i<(k + 1) loop
	sql:=sql||'k'||i||',';
	i := i + 1;	
 end loop;
sql:=sql||'0::integer as iter from ';


i := 1;
while i<(k + 1) loop
	sql:=sql||'(select array[';
	 j := 1;
	while j<=(column_number) loop
          if (j != 1) then
             sql := sql ||',';
          end if;
	  --sql:=sql||'"'||column_name[j]||'"';
		if column_array_length[j] < 1 then
			sql:=sql||'"'||column_name[j]||'"';
		else
			l := 1;
			while l <= column_array_length[j] loop
				if l != 1 then
					sql := sql || ',';
				end if;
				sql:=sql||'"'||column_name[j]||'"['||l||']';
				l := l + 1;
			end loop;
		end if;
		j := j + 1;
	end loop;



	sql:=sql||'] k'||i||',';

	if i=1 then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id'; 
	else sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id inner join ';
	end if;
	end if;
	i := i + 1;
 end loop;
 sql :=  sql||' distributed by (sample_id)';
--raise notice '7 asdf sql:%',sql;
execute sql;

sql:='drop table if exists '||temptablename||tmp_res_4||';create temp table '||temptablename||tmp_res_4||' as select sample_id,stable,';


i := 1;
column_array_index := 1;
first := true;
temp_index := 0;
while i<column_number+1 loop
	sql:=sql||'array[';
	j:=1;
		first := true;
		column_array_index := temp_index + 1;
		--sql:=sql||'k'||j||'['||i||']';
		if column_array_length[i] < 1 then
			j := 1;
			while j<=k loop
				if first is true then
					first := false;
				else
					sql := sql||',';
				end if;
				sql := sql||'k'||j||'['||column_array_index||']';
				j := j + 1;
			end loop;
		else
			l := 1;
			while l <= column_array_length[i] loop
				j := 1;
				while j<=k loop

				if first is true then
					first := false;
				else
					sql := sql||',';
				end if;

				sql := sql || 'k'||j||'['||column_array_index||']';
				j := j + 1;
				end loop;
				column_array_index := column_array_index + 1;
				l := l + 1;
			end loop;
		end if;
	if column_array_length[i] < 1 then
		temp_index := temp_index + 1;
	else
		temp_index := temp_index + column_array_length[i];
	end if;
	sql:=sql||']::float[] "'||column_name[i]||'",';
	i := i + 1;
	end loop;
	sql:=sql||' iter from '||temptablename||'temp distributed by (sample_id)';
----raise notice '----create random sql:%',sql;
--raise notice '8 asdf sql:%',sql;
execute sql;

comp_sql_new:='(case when ';
i:=1;
while i<(k + 1) loop
  j:=1;
  while j<column_number+1 loop
	if column_array_length[j] < 1 then
		temp_text := column_name[j]||'"['||i||']';
		comp_sql_new:=comp_sql_new||'x."'||temp_text||'=y."'||temp_text;
	else
		l := 1;
		column_array_index := i;
		while l <= column_array_length[j] loop
			if l  != 1 then
				comp_sql_new:=comp_sql_new||' and ';
			end if;
			temp_text := column_name[j]||'"['||column_array_index||']';
			comp_sql_new:=comp_sql_new||'x."'||temp_text||'=y."'||temp_text;
			l := l + 1;
			column_array_index := column_array_index + k;
		end loop;
	end if;

  	if i!=k or j!=column_number then 
		comp_sql_new:=comp_sql_new||' and ';
	end if;
	j:=j+1;
  end loop;
  i:=i+1;
end loop;
comp_sql_new:=comp_sql_new||' then 1 else 0 end )as stable';
----raise notice '----comp_sql_new :%',comp_sql_new;
------------

xx_array:='';
i := 1;
 while i<(column_number + 1) loop
	xx_array:=xx_array||'array[';

--	xx_array:=xx_array||'x."'||column_name[i]||'"['||j||']';
	if (column_array_length[i] < 1) then
		j := 1;
		while j<=k loop
		if j != 1 then
			xx_array := xx_array||',';
		end if;
		xx_array:=xx_array||'x."'||column_name[i]||'"['||j||']';
		j := j + 1;
		end loop;
	else
		l := 1;
		column_array_index := 1;
		while l <= column_array_length[i] loop
			j := 1;
			while j<=k loop
			if l != 1 or j != 1 then
				xx_array:=xx_array||',';
			end if;
			xx_array:=xx_array||'x."'||column_name[i]||'"['||column_array_index||']';
			column_array_index := column_array_index + 1;
			j := j + 1;
			end loop;
			l :=  l + 1;
		end loop;
	end if;
	xx_array:=xx_array||']::float[] "'||column_name[i]||'",';
	i := i + 1;
 end loop;
-- --raise notice 'xx_array:%',xx_array;
 
 --------tmp_res_3 judge which sample is stable----
sql:='drop table if exists '||temptablename||tmp_res_3||';create temp table '||temptablename||tmp_res_3||' as
(
	select 
		x.sample_id,
	 	'||comp_sql_new||','||xx_array
	 	||run||' as iter
	from  '||temptablename||tmp_res_4||' x, '||temptablename||'_random_new  y
	where x.sample_id=y.sample_id

)
distributed by(sample_id)
;
';
----------------

--raise notice '9 asdf sql:%',sql;
execute sql;

sql:='insert into '||temptablename||tmp_res_3||' (select a.* from '||temptablename||'_random_new a left join '||temptablename||tmp_res_3||' as b on a.sample_id=b.sample_id';
sql:=sql||' where b.sample_id is null);';

sql:=sql||'drop table if exists '||temptablename||'temp1;create temp table '||temptablename||'temp1 as select * from '||temptablename||tmp_res_3||' distributed by (sample_id);';
sql:=sql||'drop table if exists '||temptablename||'_random_new;';
sql:=sql||'alter table '||temptablename||'temp1 rename to '||temptablename||'_random_new;';
--raise notice '10 asdf sql:%',sql;
execute sql;


--raise notice '11 asdf sql:%',sql;
execute 'select count(*)  from  '||temptablename||'_random_new where stable=0;' into none_stable;--into '||none_stable||'


--raise notice '-------------------none_stable:%',none_stable;

if none_stable=0
then
	exit;
end if;

run := run+1;

end loop;
---------Adjust stable end--------------

sql:='select array[sample_id,len]
from
(
	select sample_id,len,row_number() over(order by len) as seq 
	from
	(
		select sample_id,avg(len) as len
		from
		(
		select sample_id,alpine_miner_kmeans_distance_result('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as len
			from '||temptablename||'copy x inner join '||temptablename||'_random_new y on y.stable=1
			)a
		 	group by 1
		)b
)z
where seq=1';

--raise notice '----get sample sql:%',sql;

--raise notice '12 asdf sql:%',sql;
execute sql into resultarray;
sampleid:=resultarray[1];

if sampleid is null then 
sampleid:=0;
nullflag:=1;
 end if;

--------deal result---------------- in (select sample_id from '||temptablename||'tmp_res_4) 
result1:='result1';
--raise notice '13 asdf sql:%',sql;
execute 'drop table if exists '||temptablename||result1;

--raise notice '14 asdf sql:%',sql;
sql := 'create temp table '||temptablename||result1||' as 
(
	select * from  '||temptablename||'_random_new  where sample_id ='||sampleid||'
)distributed by(sample_id);'
;
--raise notice '141 asdf sql:%',sql;
execute sql;

if nullflag=1 then
sql:='select len
from
(
	select sample_id,len,row_number() over(order by len) as seq 
	from
	(
		select sample_id,avg(len) as len
		from
		(
		select sample_id,alpine_miner_kmeans_distance_result('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as len
			from '||temptablename||'copy x inner join '||temptablename||result1||' y on y.stable=0
			)a
		 	group by 1
		)b
)z
where seq=1';
--raise notice '15 asdf sql:%',sql;
execute sql into tempsum;
--raise notice '-------------------tempsum:%',tempsum;
resultarray[2]:=tempsum;
end if;

--raise notice '16 asdf sql:%',sql;
execute 'drop table if exists '||temptablename||'result2; create temp table '||temptablename||'result2 as select *,0::integer '||temptablename||'copy_flag from '||temptablename||'copy  distributed randomly;';





sql:='
	drop table if exists '||temptablename||'table_name_temp;create temp table '||temptablename||'table_name_temp as
		(
		select '||alpine_id||' as temp_id,alpine_miner_kmeans_distance_loop('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as '||clustername||' 
		from '||temptablename||'result2 x inner join '||temptablename||result1||' y on x.'||temptablename||'copy_flag=0

		)  distributed randomly ;';

--raise notice '17 asdf sql:%',sql;
execute sql;

resultarray[1]:=run;

RETURN resultarray;
 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE;


CREATE OR REPLACE FUNCTION alpine_miner_kmeans_c_array_1_5(table_name text, table_name_withoutschema text, column_name text[], column_number integer, id text, tempid text, clustername text, k integer, max_run integer, max_iter integer, distance integer)
  RETURNS double precision[] AS
$BODY$
DECLARE
    run integer:=1;
    none_stable integer;
    tmp_res_1 varchar(50);
    tmp_res_2 varchar(50);
    tmp_res_3 varchar(50);
    tmp_res_4 varchar(50);
    result1 varchar(50);
    column_array text;
    avg_array text;
    x_array text;
    i integer := 0;
    j integer := 0;
    test integer;
    sql text;
    sql1 text:='';
    temptablename text;
    column_all text;
    comp_sql text;
    result_sql text;
    sampleid integer;
    sample_array text:='';
    data_array text;
    roww record;
    init_array text;
    init_array1 text;
    sample_array3 text[];
    sample_array1 text:='';
    sample_array2 text:='';
    column_new text:='';
     xx_array text;
     comp_sql_new text;
     alpine_id text;
     resultarray float[2];
    tempsum float;
    nullflag smallint:=0;
  
BEGIN

temptablename:=table_name_withoutschema;

if id='null'
then 
sql:= 'create temp table '||temptablename||'copy as(select *,row_number() over () '||tempid||' from '||table_name||' where ';
alpine_id:=tempid;
else
sql:= 'create temp table '||temptablename||'copy as(select * from '||table_name||' where ';
alpine_id:=id;
end if;

i := 1;
while i < (column_number) loop
	sql:=sql||' "'||column_name[i]||'" is not null and ';
	i := i + 1;	
end loop;
sql:=sql||' "'||column_name[i]||'" is not null';


sql:=sql||')distributed by('||alpine_id||')';

raise notice '----create copy sql:%',sql;
execute sql;

column_array := column_name[1];

i := 2;
while i < (column_number + 1) loop
	column_array := column_array||',"'||column_name[i]||'"';
	i := i + 1;
end loop;


-------------------------------
sql:='create temp table '||temptablename||'init as select tablek1.seq sample_id,0::smallint as stable,';
i := 1;
while i<(k + 1) loop
	sql:=sql||'k'||i||',';
	i := i + 1;
	end loop;
	sql:=sql||'0::integer as iter from';
i := 1;
 while i<(k + 1) loop
sql:=sql||'(select array[';
	 j := 1;
	while j<(column_number) loop
	  sql:=sql||'"'||column_name[j]||'",';
	  j := j + 1;
	end loop;
	sql:=sql||'"'||column_name[j]||'"] k'||i||',';
	if i=1 then sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq'; 
	else sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq inner join ';end if;
	end if;
	i := i + 1;
 end loop;
sql:=sql||'  distributed by (sample_id) ';
raise notice '----sql sql:%',sql;
execute sql;

sql:='create temp table '||temptablename||'_random_new as select sample_id,stable,';
i := 1;
while i<column_number+1 loop
	sql:=sql||'array[';
	j:=1;
	while j<k loop
	sql:=sql||'k'||j||'['||i||'],';
	j := j + 1;
	end loop;
	sql:=sql||'k'||j||'['||i||']]::float[] "'||column_name[i]||'",';
	i := i + 1;
	end loop;
	sql:=sql||' iter from '||temptablename||'init distributed by (sample_id)';
raise notice '----create random sql:%',sql;
execute sql;
-------------------------------
------generate random table start------

i := 1;
sample_array1:=sample_array1||'array[';
while i<(k + 1) loop
	 j := 1;
	while j<(column_number+1) loop
	if i=k and j=column_number then
	 sample_array1:=sample_array1||'y."'||column_name[j]||'"['||i||']]::float[]';
	 else
	 sample_array1:=sample_array1||'y."'||column_name[j]||'"['||i||'],';
	  end if;
	  j := j + 1;
	end loop;
	i := i + 1;
 end loop;
 
raise notice '----sample_array1 sql:%',sample_array1;
---------generate random table end-------------

---------Adjust stable start--------------
while run<=max_iter  loop
tmp_res_1:='tmp_res_1'||run::varchar;
tmp_res_2:='tmp_res_2'||run::varchar;
tmp_res_3:='tmp_res_3'||run::varchar;
tmp_res_4:='tmp_res_4'||run::varchar;
i := 2;
avg_array :=  'avg("'||column_name[1]||'")::numeric(25,10) "'||column_name[1]||'"';
while i < (column_number + 1) loop
        avg_array := avg_array||',avg("'||column_name[i]||'")::numeric(25,10) "'||column_name[i]||'"';
	i := i + 1;
end loop;


------------------

data_array:='array[';
i:=1;
while i<column_number loop
data_array:=data_array||'x."'||column_name[i]||'",';
i:=i+1;
end loop;
data_array:=data_array||'x."'||column_name[i]||'"]';

---------------
sql:='create temp table '||temptablename||tmp_res_2||' (sample_id integer,'||alpine_id||' character varying,cluster_id integer) distributed by ('||alpine_id||')';
execute sql;
i:=1;
sql:='select sample_id::smallint,'||sample_array1||'::float[] from '||temptablename||'_random_new y where stable=0 order by sample_id';
-- raise notice 'sql:%',sql;
     for roww in execute sql loop
	 sample_array3=roww.array;
	 sampleid=roww.sample_id;
	 sample_array2:='';
	j:=1;
	while j<column_number*k loop
	sample_array2:=sample_array2||sample_array3[j]||',';
	j:=j+1;
	end loop;
	sample_array2:=sample_array2||sample_array3[j];
	sample_array2:='array['||sample_array2||']';
	sql1:='insert into '||temptablename||tmp_res_2||' select '||sampleid||'::smallint,'||alpine_id||',alpine_miner_kmeans_distance_loop('||sample_array2;
	sql1:=sql1||'::float[],'||data_array||'::float[],'||k||','||distance||')as cluster_id from '||temptablename||'copy x';
	  --raise notice 'sqll:%',sql1;
	 execute sql1;
	 i:=i+1;
     end loop;
---------------


--------tmp_res_2 caculate each point in random table's distance to each point in date table and get each point in date table should belong to which cluster----------
/*sql:='drop table if exists '||temptablename||tmp_res_2||';create temp table '||temptablename||tmp_res_2||' as (select 
	sample_id,'||id||',alpine_miner_kmeans_distance_loop('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as cluster_id
from '||temptablename||'copy x inner join '||temptablename||'_random_new y on y.stable=0) distributed by (sample_id,'||id||',cluster_id)';

execute sql;*/


-----tmp_res_1 caculate unstable cluster---
sql:='drop table if exists '||temptablename||tmp_res_1||'; create temp table '||temptablename||tmp_res_1||'   as
(
select 
	sample_id,
 	cluster_id,
	'||avg_array||'
from '||temptablename||tmp_res_2||'
x,'||temptablename||'copy y
where x.'||alpine_id||'=y.'||alpine_id||'
 group by 1,2
)distributed by(sample_id,cluster_id)
 ;
 ';

execute sql;
 
--raise info '------------1--------------'; 


sql:='drop table if exists '||temptablename||'temp;create temp table '||temptablename||'temp as select tablek1.sample_id,0::smallint as stable,';
i := 1;
 while i<(k + 1) loop
	sql:=sql||'k'||i||',';
	i := i + 1;	
 end loop;
sql:=sql||'0::integer as iter from ';

i := 1;
 while i<(k + 1) loop
sql:=sql||'(select array[';
	 j := 1;
	while j<(column_number) loop
	  sql:=sql||'"'||column_name[j]||'",';
	  j := j + 1;
	end loop;
	sql:=sql||'"'||column_name[j]||'"] k'||i||',';
	if i=1 then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id'; 
	else sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id inner join ';end if;
	end if;
	i := i + 1;
 end loop;
 sql:=sql||'  distributed by (sample_id) ';

execute sql;

sql:='drop table if exists '||temptablename||tmp_res_4||';create temp table '||temptablename||tmp_res_4||' as select sample_id,stable,';
i := 1;
while i<column_number+1 loop
	sql:=sql||'array[';
	j:=1;
	while j<k loop
	sql:=sql||'k'||j||'['||i||'],';
	j := j + 1;
	end loop;
	sql:=sql||'k'||j||'['||i||']]::float[] "'||column_name[i]||'",';
	i := i + 1;
	end loop;
	sql:=sql||' iter from '||temptablename||'temp distributed by (sample_id)';
raise notice '----create random sql:%',sql;
execute sql;

comp_sql_new:='(case when ';
i:=1;
while i<(k + 1) loop
j:=1;
  while j<column_number+1 loop
  if i=k and j=column_number then comp_sql_new:=comp_sql_new||'x."'||column_name[j]||'"['||i||']=y."'||column_name[j]||'"['||i||']';
	else comp_sql_new:=comp_sql_new||'x."'||column_name[j]||'"['||i||']=y."'||column_name[j]||'"['||i||'] and ';
	end if;
	j:=j+1;
  end loop;
  i:=i+1;
end loop;
comp_sql_new:=comp_sql_new||' then 1 else 0 end )as stable';
raise notice '----comp_sql_new :%',comp_sql_new;
------------

xx_array:='';
i := 1;
 while i<(column_number + 1) loop
 j:=1;
	xx_array:=xx_array||'array[';
	while j<k loop
	xx_array:=xx_array||'x."'||column_name[i]||'"['||j||'],';
	  j := j + 1;
	end loop;
	xx_array:=xx_array||'x."'||column_name[i]||'"['||j||']]::float[] "'||column_name[i]||'",';
	i := i + 1;
 end loop;
 raise notice 'xx_array:%',xx_array;
 
 --------tmp_res_3 judge which sample is stable----
sql:='drop table if exists '||temptablename||tmp_res_3||';create temp table '||temptablename||tmp_res_3||' as
(
	select 
		x.sample_id,
	 	'||comp_sql_new||','||xx_array
	 	||run||' as iter
	from  '||temptablename||tmp_res_4||' x, '||temptablename||'_random_new  y
	where x.sample_id=y.sample_id

)
distributed by(sample_id)
;
';
----------------

execute sql;

sql:='insert into '||temptablename||tmp_res_3||' (select a.* from '||temptablename||'_random_new a left join '||temptablename||tmp_res_3||' as b on a.sample_id=b.sample_id';
sql:=sql||' where b.sample_id is null);';

sql:=sql||'drop table if exists '||temptablename||'temp1;create temp table '||temptablename||'temp1 as select * from '||temptablename||tmp_res_3||' distributed by (sample_id);';
sql:=sql||'drop table if exists '||temptablename||'_random_new;';
sql:=sql||'alter table '||temptablename||'temp1 rename to '||temptablename||'_random_new;';
execute sql;


execute 'select count(*)  from  '||temptablename||'_random_new where stable=0;' into none_stable;--into '||none_stable||'


raise notice '-------------------none_stable:%',none_stable;

if none_stable=0
then
	exit;
end if;

run := run+1;

end loop;
---------Adjust stable end--------------

sql:='select array[sample_id,len]
from
(
	select sample_id,len,row_number() over(order by len) as seq 
	from
	(
		select sample_id,avg(len) as len
		from
		(
		select sample_id,alpine_miner_kmeans_distance_result('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as len
			from '||temptablename||'copy x inner join '||temptablename||'_random_new y on y.stable=1
			)a
		 	group by 1
		)b
)z
where seq=1';

raise notice '----get sample sql:%',sql;

execute sql into resultarray;
sampleid:=resultarray[1];

if sampleid is null then 
sampleid:=0;
nullflag:=1;
 end if;

--------deal result---------------- in (select sample_id from '||temptablename||'tmp_res_4) 
result1:='result1';
execute 'drop table if exists '||temptablename||result1;

execute 'create temp table '||temptablename||result1||' as 
(
	select * from  '||temptablename||'_random_new  where sample_id ='||sampleid||'
)distributed by(sample_id);'
;


if nullflag=1 then
sql:='select len
from
(
	select sample_id,len,row_number() over(order by len) as seq 
	from
	(
		select sample_id,avg(len) as len
		from
		(
		select sample_id,alpine_miner_kmeans_distance_result('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as len
			from '||temptablename||'copy x inner join '||temptablename||result1||' y on y.stable=0
			)a
		 	group by 1
		)b
)z
where seq=1';
execute sql into tempsum;
raise notice '-------------------tempsum:%',tempsum;
resultarray[2]:=tempsum;
end if;

execute 'drop table if exists '||temptablename||'result2; create temp table '||temptablename||'result2 as select *,0::integer '||temptablename||'copy_flag from '||temptablename||'copy  distributed randomly;';





sql:='
	drop table if exists '||temptablename||'table_name_temp;create temp table '||temptablename||'table_name_temp as
		(
		select '||alpine_id||' as temp_id,alpine_miner_kmeans_distance_loop('||sample_array1||'::float[],'||data_array||'::float[],'||k||','||distance||') as '||clustername||' 
		from '||temptablename||'result2 x inner join '||temptablename||result1||' y on x.'||temptablename||'copy_flag=0

		)  distributed randomly ;';

execute sql;

resultarray[1]:=run;

RETURN resultarray;
 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE;




-- Function: alpine_miner_kmeans_c_1_5(text, text, text[], integer, text, text, text, integer, integer, integer, integer)

-- DROP FUNCTION alpine_miner_kmeans_c_1_5(text, text, text[], integer, text, text, text, integer, integer, integer, integer);

CREATE OR REPLACE FUNCTION alpine_miner_kmeans_c_1_5(table_name text, table_name_withoutschema text, column_name text[], column_number integer, id text, tempid text, clustername text, k integer, max_run integer, max_iter integer, distance integer)
  RETURNS double precision[] AS
$BODY$
DECLARE
    run integer:=1;
    none_stable integer;
    tmp_res_1 varchar(50);
    tmp_res_2 varchar(50);
    tmp_res_3 varchar(50);
    tmp_res_4 varchar(50);
    result1 varchar(50);
    column_array text;
    avg_array text;
    power_array text;
    d_array text;
    d_array1 text;
    x_array text;
    comp_array text;
    i integer := 0;
    j integer := 0;
    sql text;
    sql1 text:='';
    temptablename text;
    column_all text;
    comp_sql text;
    result_sql text;
    sampleid integer;
    sample_id text;
    sample_array text:='';
    data_array text;
    roww record;
    sample_array1 text[];
    sample_array2 text:='';
    alpine_id text;
    resultarray float[2];
    tempsum float;
    nullflag smallint:=0;
  
BEGIN

temptablename:=table_name_withoutschema;

if id='null'
then 
sql:= 'create temp table '||temptablename||'copy as(select *,row_number() over () '||tempid||' from '||table_name||' where ';
alpine_id:=tempid;
else
sql:= 'create temp table '||temptablename||'copy as(select * from '||table_name||' where ';
alpine_id:=id;
end if;


i := 1;
while i < (column_number) loop
	sql:=sql||' "'||column_name[i]||'" is not null and ';
	i := i + 1;	
end loop;
sql:=sql||' "'||column_name[i]||'" is not null';


sql:=sql||')distributed by('||alpine_id||')';

execute sql;

column_array := column_name[1];

i := 2;
while i < (column_number + 1) loop
	column_array := column_array||',"'||column_name[i]||'"';
	i := i + 1;
end loop;

------generate random table start------

sql:='select tablek1.seq sample_id,0::smallint as stable,';
column_all:='';
i := 1;
 while i<(k + 1) loop
 j := 1;
	while j<(column_number+1) loop
		column_all:=column_all||'"k'||i||''||column_name[j]||'"::numeric(25,10),';
		j := j + 1;
		end loop;
	i := i + 1;	
 end loop;
sql:=sql||column_all||'0::integer as iter from ';
--random table's line count is variable max_run,default value is 10--
--The point in same sample is in same row
i := 1;
 while i<(k + 1) loop
sql:=sql||'(select ';
	 j := 1;
	while j<(column_number+1) loop
	  sql:=sql||'"'||column_name[j]||'" "k'||i||column_name[j]||'",';
	  j := j + 1;
	end loop;
	if i=1 then sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq'; 
	else sql:=sql||' row_number() over (order by random())-1 as seq from '||temptablename||'copy limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq inner join ';end if;
	end if;
	i := i + 1;
 end loop;

i := 1;
sample_array:=sample_array||'array[';
while i<(k + 1) loop
	 j := 1;
	while j<(column_number+1) loop
	if i=k and j=column_number then
	 sample_array:=sample_array||'"k'||i||column_name[j]||'"]';
	 else
	  sample_array:=sample_array||'"k'||i||column_name[j]||'",';
	  end if;
	  j := j + 1;
	end loop;
	i := i + 1;
 end loop;

sql:='create temp table '||temptablename||'_random_new as ('||sql||') distributed by (sample_id)';

execute sql;

---------generate random table end-------------

---------Adjust stable start--------------
while run<=max_iter  loop
tmp_res_1:='tmp_res_1'||run::varchar;
tmp_res_2:='tmp_res_2'||run::varchar;
tmp_res_3:='tmp_res_3'||run::varchar;
tmp_res_4:='tmp_res_4'||run::varchar;
i := 2;
avg_array :=  'avg("'||column_name[1]||'")::numeric(25,10) "'||column_name[1]||'"';
while i < (column_number + 1) loop
        avg_array := avg_array||',avg("'||column_name[i]||'")::numeric(25,10) "'||column_name[i]||'"';
	i := i + 1;
end loop;

------------------

data_array:='array[';
i:=1;
while i<column_number loop
data_array:=data_array||'"'||column_name[i]||'",';
i:=i+1;
end loop;
data_array:=data_array||'"'||column_name[i]||'"]';



--------------
sql:='create temp table '||temptablename||tmp_res_2||' (sample_id integer,'||alpine_id||' character varying,cluster_id integer) distributed by ('||alpine_id||')';
execute sql;
i:=1;
sql:='select sample_id::smallint,'||sample_array||'::float[] from '||temptablename||'_random_new where stable=0 order by sample_id';
-- raise notice 'sql:%',sql;
     for roww in execute sql loop
	 sample_array1=roww.array;
	 sampleid=roww.sample_id;
	 sample_array2:='';
	j:=1;
	while j<column_number*k loop
	sample_array2:=sample_array2||sample_array1[j]||',';
	j:=j+1;
	end loop;
	sample_array2:=sample_array2||sample_array1[j];
	sample_array2:='array['||sample_array2||']';
	sql1:='insert into '||temptablename||tmp_res_2||' select '||sampleid||'::smallint,'||alpine_id||',alpine_miner_kmeans_distance_loop('||sample_array2;
	sql1:=sql1||'::float[],'||data_array||'::float[],'||k||','||distance||')as cluster_id from '||temptablename||'copy ';
	  --raise notice 'sqll:%',sql1;
	 execute sql1;
	 i:=i+1;
     end loop;

-----tmp_res_1 caculate unstable cluster---
sql:='drop table if exists '||temptablename||tmp_res_1||'; create temp table '||temptablename||tmp_res_1||'   as
(
select 
	sample_id,
 	cluster_id,
	'||avg_array||'
from '||temptablename||tmp_res_2||'
x,'||temptablename||'copy y
where x.'||alpine_id||'=y.'||alpine_id||'
 group by 1,2
)distributed by(sample_id,cluster_id)
 ;
 ';

execute sql;
 
--raise info '------------1--------------'; 

------------
comp_sql:='(case when ';
i:=1;
while i<(k + 1) loop
j:=1;
  while j<column_number+1 loop
  if i=k and j=column_number then comp_sql:=comp_sql||'x."k'||i||column_name[j]||'"=y."k'||i||column_name[j]||'"';
	else comp_sql:=comp_sql||'x."k'||i||column_name[j]||'"=y."k'||i||column_name[j]||'" and ';
	end if;
	j:=j+1;
  end loop;
  i:=i+1;
end loop;
comp_sql:=comp_sql||' then 1 else 0 end )as stable';

-----------

----------------
sql:='select tablek1.sample_id,0::smallint as stable,';
column_all:='';
i := 1;
 while i<(k + 1) loop
 j := 1;
	while j<(column_number+1) loop
		column_all:=column_all||'"k'||i||column_name[j]||'",';
		j := j + 1;
		end loop;
	i := i + 1;	
 end loop;
sql:=sql||column_all||'0::integer as iter from ';


i := 1;
 while i<(k + 1) loop
sql:=sql||'(select ';
	 j := 1;
	while j<(column_number+1) loop
	  sql:=sql||'"'||column_name[j]||'" "k'||i||column_name[j]||'",';
	  j := j + 1;
	end loop;
	if i=1 then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id'; 
	else sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id inner join ';end if;
	end if;
	i := i + 1;
 end loop;

--------tmp_res_4 transform the point in same sample to same line.----
 sql:='drop table if exists '||temptablename||tmp_res_4||';create temp table '||temptablename||tmp_res_4||' as ('||sql||') distributed by (sample_id)';
execute sql;

x_array:='';
i := 1;
 while i<(k + 1) loop
 j:=1;
	while j<(column_number+1) loop
	x_array:=x_array||'x."k'||i||column_name[j]||'",';
	  j := j + 1;
	end loop;
	i := i + 1;
 end loop;
 raise notice 'x_array:%',x_array;
 --------tmp_res_3 judge which sample is stable----
sql:='drop table if exists '||temptablename||tmp_res_3||';create temp table '||temptablename||tmp_res_3||' as
(
	select 
		x.sample_id,
	 	'||comp_sql||','||x_array
	 	||run||' as iter
	from  '||temptablename||tmp_res_4||' x, '||temptablename||'_random_new  y
	where x.sample_id=y.sample_id

)
distributed by(sample_id)
;
';
----------------

execute sql;


sql:='insert into '||temptablename||tmp_res_3||' (select a.* from '||temptablename||'_random_new a left join '||temptablename||tmp_res_3||' as b on a.sample_id=b.sample_id';
sql:=sql||' where b.sample_id is null);';

sql:=sql||'drop table if exists '||temptablename||'_random_new;';
sql:=sql||'alter table '||temptablename||tmp_res_3||' rename to '||temptablename||'_random_new;';
execute sql;



execute 'select count(*)  from  '||temptablename||'_random_new where stable=0;' into none_stable;--into '||none_stable||'


raise notice '-------------------none_stable:%',none_stable;

if none_stable=0
then
	exit;
end if;

run := run+1;

end loop;
---------Adjust stable end--------------

sql:='select array[sample_id,len]
from
(
	select sample_id,len,row_number() over(order by len) as seq 
	from
	(
		select sample_id,avg(len) as len
		from
		(
		select sample_id,alpine_miner_kmeans_distance_result('||sample_array||'::float[],'||data_array||'::float[],'||k||','||distance||') as len
			from '||temptablename||'copy x inner join '||temptablename||'_random_new y on y.stable=1
			)a
		 	group by 1
		)b
)z
where seq=1';

raise notice '-------------------sql:%',sql;
execute sql into resultarray;
sampleid:=resultarray[1];

if sampleid is null then 
sampleid:=0;
nullflag:=1;
 end if;

--------deal result---------------- in (select sample_id from '||temptablename||'tmp_res_4) 
result1:='result1';
execute 'drop table if exists '||temptablename||result1;

execute 'create temp table '||temptablename||result1||' as 
(
	select * from  '||temptablename||'_random_new  where sample_id ='||sampleid||'
)distributed by(sample_id);'
;

if nullflag=1 then
sql:='select len
from
(
	select sample_id,len,row_number() over(order by len) as seq 
	from
	(
		select sample_id,avg(len) as len
		from
		(
		select sample_id,alpine_miner_kmeans_distance_result('||sample_array||'::float[],'||data_array||'::float[],'||k||','||distance||') as len
			from '||temptablename||'copy x inner join '||temptablename||result1||' y on y.stable=0
			)a
		 	group by 1
		)b
)z
where seq=1';
execute sql into tempsum;
raise notice '-------------------tempsum:%',tempsum;
resultarray[2]:=tempsum;
end if;


execute 'drop table if exists '||temptablename||'result2; create temp table '||temptablename||'result2 as select *,0::integer '||temptablename||'copy_flag from '||temptablename||'copy  distributed randomly;';





sql:='
	drop table if exists '||temptablename||'table_name_temp;create temp table '||temptablename||'table_name_temp as
		(
		select '||alpine_id||' as temp_id,alpine_miner_kmeans_distance_loop('||sample_array||'::float[],'||data_array||'::float[],'||k||','||distance||') as '||clustername||' 
		from '||temptablename||'result2 x inner join '||temptablename||result1||' y on x.'||temptablename||'copy_flag=0

		)  distributed randomly ;';

execute sql;

resultarray[1]:=run;


RETURN resultarray;
 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE;

-- Function: Alpine_Miner_Kmeans_distance(integer, text[], integer, integer)

-- DROP FUNCTION Alpine_Miner_Kmeans_distance(integer, text[], integer, integer);

CREATE OR REPLACE FUNCTION alpine_miner_Kmeans_distance(distancetype integer, column_name text[], column_number integer, k integer)
  RETURNS text AS
$BODY$

DECLARE
	 caculate_array text:='';
	 temp1 text:='';
	 temp2 text:='';
	 temp3 text:='';
	 temp4 text:='';
	 i integer;
	 j integer;
	 m integer;

BEGIN
	if distancetype=1 --EuclideanDistance
	then 
		i:=1;
		while i<(k + 1) loop
		j:=1;
		caculate_array:=caculate_array||'(';
		while j<column_number loop
		caculate_array:=caculate_array||'(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")*(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")+';
		j:=j+1;
		end loop; 
		if i=k then caculate_array:=caculate_array||'(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")*(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")) as d'||(i-1);
		else caculate_array:=caculate_array||'(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")*(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")) as d'||(i-1)||',';
		end if;
		i:=i+1;
		end loop;
	elsif distancetype=2	--BregmanDivergence.GeneralizedIDivergence
	then
		i:=1;
		while i<(k + 1) loop
		j:=1;
		temp1:='(';
		temp2:='(';
			while j<column_number loop
			temp1:=temp1||'(y."k'||i||column_name[j]||'"*ln(y."k'||i||column_name[j]||'"::float/x."'||column_name[j]||'"))+';
			temp2:=temp2||'(y."k'||i||column_name[j]||'"::float-x."'||column_name[j]||'")+';
			j:=j+1;
			end loop; 
		temp1:=temp1||'(y."k'||i||column_name[j]||'"*ln(y."k'||i||column_name[j]||'"::float/x."'||column_name[j]||'")))';
		temp2:=temp2||'(y."k'||i||column_name[j]||'"::float-x."'||column_name[j]||'"))';
		temp3:='('||temp1||'-'||temp2||')';
		if i=k then temp3:=temp3||'as d'||(i-1);
		else temp3:=temp3||'as d'||(i-1)||',';		
		end if;
		caculate_array:=caculate_array||temp3;
		i:=i+1;
		end loop;
	elsif distancetype=3      --BregmanDivergence.KLDivergence
	then
		i:=1;
		while i<(k + 1) loop
		j:=1;
		caculate_array:=caculate_array||'(';
		while j<column_number loop
		caculate_array:=caculate_array||'(y."k'||i||column_name[j]||'"*log(2.0,(y."k'||i||column_name[j]||'"::float/x."'||column_name[j]||'")::numeric))+';
		j:=j+1;
		end loop; 
		if i=k then caculate_array:=caculate_array||'(y."k'||i||column_name[j]||'"*log(2.0,(y."k'||i||column_name[j]||'"::float/x."'||column_name[j]||'")::numeric))) as d'||(i-1);

		else caculate_array:=caculate_array||'(y."k'||i||column_name[j]||'"*log(2.0,(y."k'||i||column_name[j]||'"::float/x."'||column_name[j]||'")::numeric))) as d'||(i-1)||',';
		end if;
		i:=i+1;
		end loop;
	elsif distancetype=4      --CamberraNumericalDistance
	then
		i:=1;
		while i<(k + 1) loop
		j:=1;
		caculate_array:=caculate_array||'(';
		while j<column_number loop
		caculate_array:=caculate_array||'(abs((x."'||column_name[j]||'"::float)-(y."k'||i||column_name[j]||'"))/abs((x."'||column_name[j]||'"::float)+(y."k'||i||column_name[j]||'")))+';
		j:=j+1;
		end loop; 
		if i=k then caculate_array:=caculate_array||'(abs((x."'||column_name[j]||'"::float)-(y."k'||i||column_name[j]||'"))/abs((x."'||column_name[j]||'"::float)+(y."k'||i||column_name[j]||'")))) as d'||(i-1);
		else caculate_array:=caculate_array||'(abs((x."'||column_name[j]||'"::float)-(y."k'||i||column_name[j]||'"))/abs((x."'||column_name[j]||'"::float)+(y."k'||i||column_name[j]||'")))) as d'||(i-1)||',';
		end if;
		i:=i+1;
		end loop;
	elsif distancetype=5      --ManhattanDistance
	then	
		i:=1;
		while i<(k + 1) loop
		j:=1;
		caculate_array:=caculate_array||'(';
		while j<column_number loop
		caculate_array:=caculate_array||'abs((x."'||column_name[j]||'"::float)-(y."k'||i||column_name[j]||'"))+';
		j:=j+1;
		end loop; 
		if i=k then caculate_array:=caculate_array||'abs((x."'||column_name[j]||'"::float)-(y."k'||i||column_name[j]||'"))) as d'||(i-1);
		else caculate_array:=caculate_array||'abs((x."'||column_name[j]||'"::float)-(y."k'||i||column_name[j]||'"))) as d'||(i-1)||',';
		end if;
		i:=i+1;
		end loop;
	
	elsif distancetype=6      --CosineSimilarityDistance
	then	
		i:=1;
		while i<(k + 1) loop
		j:=1;
		temp1:='(';
		temp2:='(';
		temp3:='(';
		while j<column_number loop
		temp1:=temp1||'(x."'||column_name[j]||'"::float*y."k'||i||column_name[j]||'")+';
		temp2:=temp2||'(x."'||column_name[j]||'"::float*x."'||column_name[j]||'")+';
		temp3:=temp3||'(y."k'||i||column_name[j]||'"::float*y."k'||i||column_name[j]||'")+';
		j:=j+1;
		end loop; 
		temp1:=temp1||'(x."'||column_name[j]||'"::float*y."k'||i||column_name[j]||'"))';
		temp2:=temp2||'(x."'||column_name[j]||'"::float*x."'||column_name[j]||'"))';
		temp3:=temp3||'(y."k'||i||column_name[j]||'"::float*y."k'||i||column_name[j]||'"))';
		if i=k then 
		temp4:='acos(case when ('||temp1||'/(sqrt('||temp2||')*sqrt('||temp3||')))>1 then 1 when ('||temp1||'/(sqrt('||temp2||')*sqrt('||temp3||')))<-1 then -1 else ('||temp1||'/(sqrt('||temp2||')*sqrt('||temp3||'))) end ) as d'||(i-1);--
		else
		temp4:='acos(case when ('||temp1||'/(sqrt('||temp2||')*sqrt('||temp3||')))>1 then 1 when ('||temp1||'/(sqrt('||temp2||')*sqrt('||temp3||')))<-1 then -1 else ('||temp1||'/(sqrt('||temp2||')*sqrt('||temp3||'))) end ) as d'||(i-1)||',';--acos
		end if;
		caculate_array:=caculate_array||temp4;
		i:=i+1;
		end loop;
		
	elsif distancetype=7	--DiceNumericalSimilarityDistance
	then
		i:=1;
		while i<(k + 1) loop
		j:=1;
		temp1:='(';
		temp2:='(';
		temp3:='(';
		while j<column_number loop
		temp1:=temp1||'(x."'||column_name[j]||'"::float)+';
		temp2:=temp2||'(y."k'||i||column_name[j]||'"::float)+';
		temp3:=temp3||'(x."'||column_name[j]||'"::float*y."k'||i||column_name[j]||'")+';
		j:=j+1;
		end loop; 
		temp1:=temp1||'(x."'||column_name[j]||'"))';
		temp2:=temp2||'(y."k'||i||column_name[j]||'"))';
		temp3:=temp3||'(x."'||column_name[j]||'"*y."k'||i||column_name[j]||'"))';
		if i=k then 
		temp4:='(-2*'||temp3||'/('||temp1||'+'||temp2||')) as d'||(i-1);
		else
		temp4:='(-2*'||temp3||'/('||temp1||'+'||temp2||')) as d'||(i-1)||',';
		end if;
		caculate_array:=caculate_array||temp4;
		i:=i+1;
		end loop;
	elsif distancetype=8	--InnerProductSimilarityDistance
	then
		i:=1;
		while i<(k + 1) loop
		j:=1;
		caculate_array:=caculate_array||'-(';
		while j<column_number loop
		caculate_array:=caculate_array||'(x."'||column_name[j]||'"::float*y."k'||i||column_name[j]||'")+';
		j:=j+1;
		end loop; 
		if i=k then caculate_array:=caculate_array||'(x."'||column_name[j]||'"::float*y."k'||i||column_name[j]||'")) as d'||(i-1);
		else caculate_array:=caculate_array||'(x."'||column_name[j]||'"::float*y."k'||i||column_name[j]||'")) as d'||(i-1)||',';
		end if;
		caculate_array:=caculate_array||temp4;
		i:=i+1;
		end loop;
	elsif distancetype=9	--JaccardNumericalSimilarityDistance
	then
		i:=1;
		while i<(k + 1) loop
		j:=1;
		temp1:='(';
		temp2:='(';
		temp3:='(';
		while j<column_number loop
		temp1:=temp1||'(x."'||column_name[j]||'"::float)+';
		temp2:=temp2||'(y."k'||i||column_name[j]||'"::float)+';
		temp3:=temp3||'(x."'||column_name[j]||'"::float*y."k'||i||column_name[j]||'")+';
		j:=j+1;
		end loop; 
		temp1:=temp1||'(x."'||column_name[j]||'"))';
		temp2:=temp2||'(y."k'||i||column_name[j]||'"))';
		temp3:=temp3||'(x."'||column_name[j]||'"*y."k'||i||column_name[j]||'"))';
		if i=k then 
		temp4:='(-'||temp3||'/('||temp1||'+'||temp2||'-'||temp3||')) as d'||(i-1);
		else
		temp4:='(-'||temp3||'/('||temp1||'+'||temp2||'-'||temp3||')) as d'||(i-1)||',';
		end if;
		caculate_array:=caculate_array||temp4;
		i:=i+1;
		end loop;
/*	elseif distancetype=10	--ChebychevDistance 
	--select case when a1>a2 and a1>a3 and a1>a4 then a1 when a2>a3 and a2>a4 then a2 when a3>a4 then a3 else a4 end as d0
	then 
		i:=1;
		while i<(k + 1) loop
		j:=1;
		caculate_array:=caculate_array||'case ';
			while j<column_number loop
			m:=1;
			caculate_array:=caculate_array||' when ';
				while m<column_number-j loop
					caculate_array:=caculate_array||'abs(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")>abs(x."'||column_name[j+m]||'"::float-y."k'||i||column_name[j+m]||'") and ';
					m:=m+1;
				end loop;
				caculate_array:=caculate_array||'abs(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'")>abs(x."'||column_name[j+m]||'"::float-y."k'||i||column_name[j+m]||'") then abs(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'") ';
			j:=j+1;
			end loop; 
		if i=k then caculate_array:=caculate_array||' else abs(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'") end as d'||(i-1);
		else caculate_array:=caculate_array||' else abs(x."'||column_name[j]||'"::float-y."k'||i||column_name[j]||'") end as d'||(i-1)||',';
		end if;
		i:=i+1;
		end loop;*/
	else
	end if;

raise notice 'caculate_array:%',caculate_array;
RETURN caculate_array;
 
END;
$BODY$
  LANGUAGE 'plpgsql' IMMUTABLE;
-- Function: Alpine_Miner_kmeans_sp(text, text, text[], integer, text, integer, integer, integer, integer)

-- DROP FUNCTION Alpine_Miner_kmeans_sp(text, text, text[], integer, text, integer, integer, integer, integer);

CREATE OR REPLACE FUNCTION alpine_miner_kmeans_sp_1_5(table_name text, table_name_withoutschema text, column_name text[], column_number integer, id text, k integer, max_run integer, max_iter integer, distance integer)
  RETURNS integer AS
$BODY$
DECLARE
    run integer:=1;
    none_stable integer;
    tmp_res_1 varchar(50);
    tmp_res_2 varchar(50);
    tmp_res_3 varchar(50);
    tmp_res_4 varchar(50);
    result1 varchar(50);
    column_array text;
    columnname text;
    avg_array text;
    power_array text;
    d_array text;
    d_array1 text;
    x_array text;
    comp_array text;
    i integer := 0;
    j integer := 0;
    sql text;
    temptablename text;
    column_all text;
    caculate_array text;
    comp_sql text;
    result_sql text;
    sampleid integer;
  
BEGIN

temptablename:=table_name_withoutschema;

execute 'create temp table '||temptablename||'copy as(select * from '||table_name||' )distributed by('||id||')';

column_array := column_name[1];

i := 2;
while i < (column_number + 1) loop
	column_array := column_array||',"'||column_name[i]||'"';
	i := i + 1;
end loop;

------generate random table start------

sql:='select tablek1.seq sample_id,0::smallint as stable,';
column_all:='';
i := 1;
 while i<(k + 1) loop
 j := 1;
	while j<(column_number+1) loop
		column_all:=column_all||'"k'||i||''||column_name[j]||'"::numeric(25,10),';
		j := j + 1;
		end loop;
	i := i + 1;	
 end loop;
sql:=sql||column_all||'0::integer as iter from ';
--random table's line count is variable max_run,default value is 10--
--The point in same sample is in same row
i := 1;
 while i<(k + 1) loop
sql:=sql||'(select ';
	 j := 1;
	while j<(column_number+1) loop
	  sql:=sql||'"'||column_name[j]||'" "k'||i||column_name[j]||'",';
	  j := j + 1;
	end loop;
	if i=1 then sql:=sql||' row_number() over (order by random())-1 as seq from '||table_name||' limit '||max_run||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' row_number() over (order by random())-1 as seq from '||table_name||' limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq'; 
	else sql:=sql||' row_number() over (order by random())-1 as seq from '||table_name||' limit '||max_run||') as tablek'||i||' on tablek'||(i-1)||'.seq=tablek'||i||'.seq inner join ';end if;
	end if;
	i := i + 1;
 end loop;

sql:='create temp table '||temptablename||'_random_new as ('||sql||') distributed by (sample_id)';
raise notice 'sql:%',sql;
execute sql;

---------generate random table end-------------

---------Adjust stable start--------------
while run<=max_iter  loop
tmp_res_1:='tmp_res_1'||run::varchar;
tmp_res_2:='tmp_res_2'||run::varchar;
tmp_res_3:='tmp_res_3'||run::varchar;
tmp_res_4:='tmp_res_4'||run::varchar;
i := 2;
avg_array :=  'avg("'||column_name[1]||'")::numeric(25,10) "'||column_name[1]||'"';
while i < (column_number + 1) loop
        avg_array := avg_array||',avg("'||column_name[i]||'")::numeric(25,10) "'||column_name[i]||'"';
	i := i + 1;
end loop;


i := 0;
j := 0;
d_array := 'case ';
d_array1 := 'case ';
while i < k - 1 loop
	j := i+1;
	d_array := d_array||' when d'||i||'<=d'||j;
	d_array1 := d_array1||' when d'||i||'<=d'||j;
	j := j + 1;
	while j < k loop
		d_array := d_array||' and d'||i||'<=d'||j;
		d_array1 := d_array1||' and d'||i||'<=d'||j;
		j:= j+1;
	end loop;
	d_array := d_array||' then '||i;
	d_array1 := d_array1||' then d'||i;
	i := i + 1;
end loop;
d_array := d_array||' else '||(k-1)||' end';
d_array1 := d_array1||' else d'||(k-1)||' end';
--d_array1 example:d0<=d1 and d0<=d2 then d0 when d1<=d2 then d1 else d2 end
------------------
caculate_array:='';

columnname:='array[';
i:=1;
while i<column_number loop
columnname:=columnname||''''||column_name[i]||''',';
i:=i+1;
end loop;
columnname:=columnname||''''||column_name[i]||''']';

raise notice 'column_name:%',columnname;

sql:='select alpine_miner_Kmeans_distance('||distance||','||columnname||','||column_number||','||k||')';
raise notice 'sql:%',sql;
execute sql into caculate_array;

--------tmp_res_2 caculate each point in random table's distance to each point in date table and get each point in date table should belong to which cluster----------
sql:='drop table if exists '||temptablename||tmp_res_2||';create temp table '||temptablename||tmp_res_2||' as (select 
	sample_id,'||id||',
	     '||d_array||' as cluster_id
from
(
select 
sample_id,'||id||',	     
'||caculate_array||'
 from '||temptablename||'copy x inner join '||temptablename||'_random_new y
   on y.stable=0) as foo) distributed by (sample_id,'||id||',cluster_id)';

execute sql;

-----tmp_res_1 caculate unstable cluster---
sql:='drop table if exists '||temptablename||tmp_res_1||'; create temp table '||temptablename||tmp_res_1||'   as
(
select 
	sample_id,
 	cluster_id,
	'||avg_array||'
from '||temptablename||tmp_res_2||'
x,'||temptablename||'copy y
where x.'||id||'=y.'||id||'
 group by 1,2
)distributed by(sample_id,cluster_id)
 ;
 ';

execute sql;
 
--raise info '------------1--------------'; 

------------
comp_sql:='(case when ';
i:=1;
while i<(k + 1) loop
j:=1;
  while j<column_number+1 loop
  if i=k and j=column_number then comp_sql:=comp_sql||'x."k'||i||column_name[j]||'"=y."k'||i||column_name[j]||'"';
	else comp_sql:=comp_sql||'x."k'||i||column_name[j]||'"=y."k'||i||column_name[j]||'" and ';
	end if;
	j:=j+1;
  end loop;
  i:=i+1;
end loop;
comp_sql:=comp_sql||' then 1 else 0 end )as stable';

-----------

----------------
sql:='select tablek1.sample_id,0::smallint as stable,';
column_all:='';
i := 1;
 while i<(k + 1) loop
 j := 1;
	while j<(column_number+1) loop
		column_all:=column_all||'"k'||i||column_name[j]||'",';
		j := j + 1;
		end loop;
	i := i + 1;	
 end loop;
sql:=sql||column_all||'0::integer as iter from ';


i := 1;
 while i<(k + 1) loop
sql:=sql||'(select ';
	 j := 1;
	while j<(column_number+1) loop
	  sql:=sql||'"'||column_name[j]||'" "k'||i||column_name[j]||'",';
	  j := j + 1;
	end loop;
	if i=1 then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' inner join ';
	else if i=k then sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id'; 
	else sql:=sql||' sample_id from '||temptablename||tmp_res_1||' where cluster_id='||(i-1)||') as tablek'||i||' on tablek'||(i-1)||'.sample_id=tablek'||i||'.sample_id inner join ';end if;
	end if;
	i := i + 1;
 end loop;

--------tmp_res_4 transform the point in same sample to same line.----
 sql:='drop table if exists '||temptablename||tmp_res_4||';create temp table '||temptablename||tmp_res_4||' as ('||sql||') distributed by (sample_id)';
execute sql;

x_array:='';
i := 1;
 while i<(k + 1) loop
 j:=1;
	while j<(column_number+1) loop
	x_array:=x_array||'x."k'||i||column_name[j]||'",';
	  j := j + 1;
	end loop;
	i := i + 1;
 end loop;
 raise notice 'x_array:%',x_array;
 --------tmp_res_3 judge which sample is stable----
sql:='drop table if exists '||temptablename||tmp_res_3||';create temp table '||temptablename||tmp_res_3||' as
(
	select 
		x.sample_id,
	 	'||comp_sql||','||x_array
	 	||run||' as iter
	from  '||temptablename||tmp_res_4||' x, '||temptablename||'_random_new  y
	where x.sample_id=y.sample_id

)
distributed by(sample_id)
;
';
----------------

execute sql;


execute 'delete from '||temptablename||'_random_new a using '||temptablename||tmp_res_3||' b where a.sample_id=b.sample_id';



execute 'insert into  '||temptablename||'_random_new select * from '||temptablename||tmp_res_3;



execute 'select count(*)  from  '||temptablename||'_random_new where stable=0;' into none_stable;--into '||none_stable||'


raise notice '-------------------none_stable:%',none_stable;

if none_stable=0
then
	exit;
end if;

run := run+1;

end loop;
---------Adjust stable end--------------

sql:='select sample_id
from
(
	select sample_id,row_number() over(order by len) as seq 
	from
	(
		select sample_id,sum(len) as len
		from
		(
				select 
					sample_id,'||id||',
					'||d_array1||' as len
				from
				(	     
				select 
					    	sample_id,
					    	'||id||',
						'||caculate_array||'
					    from
					      '||temptablename||'copy x inner join '||temptablename||'_random_new y
					      on y.stable=1
				)t
			)a
		 	group by 1
		)b
)z
where seq=1';



execute sql into sampleid;

if sampleid is null then sampleid=0;
 end if;

--------deal result---------------- in (select sample_id from '||temptablename||'tmp_res_4) 
result1:='result1';
execute 'drop table if exists '||temptablename||result1;

execute 'create temp table '||temptablename||result1||' as 
(
	select * from  '||temptablename||'_random_new  where sample_id ='||sampleid||'
)distributed by(sample_id);'
;

execute 'drop table if exists '||temptablename||'result2; create temp table '||temptablename||'result2 as select *,0::integer '||temptablename||'copy_flag from '||temptablename||'copy  distributed randomly;';


result_sql:='select '||id||' as temp_id,'||d_array||' as cluster from
(
select x.'||id||','||caculate_array||' 
from '||temptablename||'result2 x inner join '||temptablename||result1||' y on x.'||temptablename||'copy_flag=0
) as foo
';
raise notice 'result_sql:%',result_sql;



execute '
	drop table if exists '||temptablename||'table_name_temp;create temp table '||temptablename||'table_name_temp as
		(
		'||result_sql||'
		)  distributed randomly;';


RETURN run;
 
END;
$BODY$
  LANGUAGE 'plpgsql' VOLATILE;



  CREATE OR REPLACE FUNCTION alpine_miner_float8_mregr_accum(state DOUBLE PRECISION[], y DOUBLE PRECISION, x DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_float8_mregr_combine(state1 DOUBLE PRECISION[], state2 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

DROP AGGREGATE IF EXISTS alpine_miner_mregr_coef(DOUBLE PRECISION,DOUBLE PRECISION[]);
CREATE AGGREGATE alpine_miner_mregr_coef(DOUBLE PRECISION,DOUBLE PRECISION[]) (
    SFUNC=alpine_miner_float8_mregr_accum,
    STYPE=float8[],
    prefunc=alpine_miner_float8_mregr_combine,
    INITCOND='{0}'
);

CREATE OR REPLACE FUNCTION alpine_miner_lr_ca_beta_accum(state DOUBLE PRECISION[],beta float[],columns float[],add_intercept boolean, weight float, y int, times int )
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_lr_ca_he_accum(state DOUBLE PRECISION[],beta float[],columns float[],add_intercept boolean, weight float)
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION alpine_miner_lr_ca_he_de_accum(state DOUBLE PRECISION[],beta float[],columns float[],add_intercept boolean, weight float, y int)
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_lr_ca_fitness(beta float[],columns float[],add_intercept boolean, weight float, label_value int) RETURNS float
    AS 'alpine_miner', 'alpine_miner_lr_ca_fitness'
    LANGUAGE C immutable ;
CREATE OR REPLACE FUNCTION alpine_miner_lr_ca_pi(beta float[],columns float[],add_intercept boolean) RETURNS float
    AS 'alpine_miner', 'alpine_miner_lr_ca_pi'
    LANGUAGE C immutable ;
CREATE OR REPLACE FUNCTION alpine_miner_lr_combine(state1 DOUBLE PRECISION[], state2 DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;
drop function if exists alpine_miner_lr_ca_beta(float[],float[],boolean, float, int, int);
drop function if exists alpine_miner_lr_ca_he(float[],float[],boolean, float) ;
drop function if exists alpine_miner_lr_ca_he_de(float[],float[],boolean, float, int);
DROP AGGREGATE IF EXISTS alpine_miner_lr_ca_beta(float[],float[],boolean, float, int, int);
CREATE AGGREGATE alpine_miner_lr_ca_beta(float[],float[],boolean, float, int, int) (
    SFUNC=alpine_miner_lr_ca_beta_accum,
    STYPE=float8[],
    prefunc=alpine_miner_lr_combine,
    INITCOND='{0}'
);

DROP AGGREGATE IF EXISTS alpine_miner_lr_ca_he(float[],float[],boolean, float);
CREATE AGGREGATE alpine_miner_lr_ca_he(float[],float[],boolean, float) (
    SFUNC=alpine_miner_lr_ca_he_accum,
    STYPE=float8[],
    prefunc=alpine_miner_lr_combine,
    INITCOND='{0}'
);


DROP AGGREGATE IF EXISTS alpine_miner_lr_ca_he_de(float[],float[],boolean, float, int);
CREATE AGGREGATE alpine_miner_lr_ca_he_de(float[],float[],boolean, float, int) (
    SFUNC=alpine_miner_lr_ca_he_de_accum,
    STYPE=float8[],
    prefunc=alpine_miner_lr_combine,
    INITCOND='{0}'
);

create OR REPLACE function alpine_miner_null_to_0(x bigint)
returns bigint AS
$BODY$
BEGIN
if x is null
then return 0;
else return x;
end if;END;
$BODY$
LANGUAGE 'plpgsql' immutable;

create OR REPLACE function alpine_miner_null_to_0(x float)
returns float AS
$BODY$
BEGIN
if x is null
then return 0;
else return x;
end if;END;
$BODY$
LANGUAGE 'plpgsql' immutable;
CREATE OR REPLACE FUNCTION alpine_miner_pcaresult(x DOUBLE PRECISION[],Y DOUBLE PRECISION[])
RETURNS DOUBLE PRECISION[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;




       
-- Function: alpine_miner_initpca(text, text, text[], text, text)

-- DROP FUNCTION alpine_miner_initpca(text, text, text[], text, text);

CREATE OR REPLACE FUNCTION alpine_miner_initpca(tablename text, valueouttable text, infor text[], createway text, dropifexists text, append_only_string TEXT, ending_string TEXT)
  RETURNS double precision[] AS
$BODY$
DECLARE 
	columnnumber float;
	i integer;
	j integer;
	rownumber float;
	alpine_pcadataindex integer;
	temp float;
	sql text;
	sql1 text;
	sqlnotnull text;
	total integer;
	result  double precision[];
	vari double precision[];
BEGIN

	columnnumber:= alpine_miner_get_array_count(infor);
	execute 'select count(*) from '||tablename into rownumber;
	total:=columnnumber*(columnnumber+1)/2;

	IF dropIfExists='yes'
	THEN execute 'Drop table IF EXISTS '||valueouttable;
	END IF;
	sqlnotnull:=' where  '||infor[1]||' is not null';
	sql:= ' '||infor[1]||' ';
	sql1:=sql||' double precision';
	for i in 2..columnnumber loop
		sql:=sql||', '||infor[i]||'';
		sqlnotnull:=sqlnotnull||' and '||infor[i]||' is not null ';
		sql1:=sql1||', '||infor[i]||' double precision';
	end loop;
	
	
	execute 'create table '||valueouttable||' ('||sql1||',"alpine_pcadataindex" integer,"alpine_pcaevalue" float,"alpine_pcacumvl" float,"alpine_pcatotalcumvl" float)  '||append_only_string|| ' ' ||ending_string;


	
		
		
	IF createway='cov-pop' 
	THEN 
	execute  'select  alpine_miner_covar(array['||sql||'])  from  '||tablename||' '||sqlnotnull  into result;
	
	ELSE IF createway='cov-sam'
	THEN 
		execute  'select  alpine_miner_covar_sam(array['||sql||'])  from  '||tablename||' '||sqlnotnull into result;
	ELSE IF createway='corr'
	THEN 
		execute  'select  alpine_miner_corr(array['||sql||'])  from  '||tablename||' '||sqlnotnull into result;
	END IF;
	END IF;
	END IF;	
	
RETURN result;

END;

 $BODY$
  LANGUAGE plpgsql VOLATILE;

-- Function: alpine_miner_pcaresult(text, text[], text, text[], text, integer, text)

-- DROP FUNCTION alpine_miner_pcaresult(text, text[], text, text[], text, integer, text);

CREATE OR REPLACE FUNCTION alpine_miner_pcaresult(tablename text, infor text[], outtablename text, remaincolumns text[], outvaluetable text, pcanumber integer, dropifexists text, append_only_string TEXT, ending_string TEXT)
  RETURNS double precision[] AS
$BODY$
DECLARE 
	columnnumber integer;
	i integer;
	j integer;
	temp float;
	wrongnumber float;
	err float;
	remconames text;
	maxerror float;
	tempqvalue float;
	c float :=0;
	sumsql text;
	sumarrayname  text;
	notnulltext text;
	valuesarray float[];
	arraytext text;
	valuestext text;
	temparray float[];
	totalsql text;
	valuesql text;
	tempstring text;
	result  double precision[];
	tempnumber float;
	temprecord float[];
	remainnumber int;
BEGIN

	columnnumber:= alpine_miner_get_array_count(infor);
	if remaincolumns  is not null
	then 	remainnumber:= alpine_miner_get_array_count(remaincolumns);
		remconames:=' , '||array_to_string(remaincolumns,',');
	else  remconames:=' ';
	end if;
	IF dropIfExists='yes'
	THEN execute 'Drop table IF EXISTS '||outtablename||' ';
	END IF;
	
	i        := 1;
	sumsql:=' ';
	sumarrayname:=array_to_string(infor,',');
	while i <= pcanumber loop
			execute 'select array[' || sumarrayname|| '] from ' || outvaluetable ||
             ' where  "alpine_pcadataindex"=' ||
             (i - 1)   into temparray;
                      IF i>1
              THEN valuesarray:=array_cat(valuesarray,temparray);
		arraytext:=arraytext||' , arr['||i||'] alpine_pcaattr'||i;
             ELSE 
             valuesarray:=temparray;
            			arraytext:='arr[1] alpine_pcaattr1 ';
              END IF;
              i:=i+1;
	end loop;

	notnulltext:=array_to_string(infor,' is not null and ');
	
	valuestext:=array_to_string(valuesarray,',');
	execute 'create table ' || outtablename || ' ' ||append_only_string||' as select '|| arraytext ||'  '||remconames||' from (select alpine_miner_pcaresult(array['||sumarrayname||'],array['||valuestext||']) arr '||remconames||' from 	' || tablename ||' where '||notnulltext||' is not null ) AS foo '||ending_string;
  
 
	
RETURN result;

END;

 $BODY$
  LANGUAGE plpgsql VOLATILE;

drop type IF EXISTS plda_assign_topics cascade;
CREATE   TYPE plda_assign_topics AS (
       assign bigint[],
       topic_count bigint[]
);


CREATE OR REPLACE FUNCTION alpine_plda_gene(columnarray bigint[], glassign bigint[],wordtopic bigint[],
lastassign bigint[],lasttopic bigint[],alpha double precision,beta double precision , wordnumber bigint,topicnumber bigint)
RETURNS plda_assign_topics
AS 'alpine_miner','alpine_plda_gene'
LANGUAGE C
IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION alpine_plda_first(x bigint, y bigint)
RETURNS plda_assign_topics
AS 'alpine_miner','alpine_plda_first'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_plda_word_topic(IN arr integer[], IN topicnumber integer, IN wordnumber integer, OUT ret integer[])
  RETURNS integer[] AS
$BODY$
       SELECT $1[(($3-1)*$2 + 1):(($3-1)*$2 + $2)];
$BODY$
  LANGUAGE sql VOLATILE;

CREATE OR REPLACE FUNCTION alpine_plda_count_accum(state bigint[],data bigint[], x bigint[],y bigint,z bigint)
RETURNS bigint[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_plda_count_combine(state1 bigint[], state2 bigint[])
RETURNS bigint[]
AS 'alpine_miner'
LANGUAGE C
IMMUTABLE STRICT;



DROP AGGREGATE IF EXISTS alpine_plda_count(  bigint[],   bigint[],  bigint,  bigint);
CREATE AGGREGATE alpine_plda_count(  bigint[],   bigint[],  bigint,  bigint) (
    SFUNC=alpine_plda_count_accum,
    STYPE=bigint[],
    prefunc=alpine_plda_count_combine,
    INITCOND='{0}'
);



CREATE OR REPLACE FUNCTION alpine_miner_plda_train(content_table text, docidcolumn text, doccontentcolumn text, alpha double precision, beta double precision, topicnumber integer, dictable text, diccontentcolumn text, iteration_number integer, tempouttable text, tempouttable1 text, outtable text, outappendonlystring text, outdistributestring text, doctopictable text,  doctopicoutappendonlystring text, doctopicoutdistributestring text, topicouttable text, topicoutappendonlystring text, topicoutdistributestring text)
  RETURNS double precision AS
$BODY$
DECLARE 
	geneinputtable text;
	geneoutputtable text;
	tempiteration bigint;
	sql text;
	wordtopic bigint[];--each word counts in every topic
	alldoctopic  bigint[];--counts for each topic
	myrecord record;
	diccontent text[];
	wordnumber bigint;
BEGIN
	
	sql:= 'select  '||diccontentcolumn||' as content from '||dictable||' ';
	for myrecord in execute sql loop
		diccontent:=myrecord.content;
	end loop;
	wordnumber:=array_upper(diccontent,1);
	execute 'CREATE temp TABLE '||tempouttable||' ( alpinepldagenera bigint , '||docidcolumn||' bigint , '|| doccontentcolumn||' bigint[],  alpinepldainfo plda_assign_topics)  WITH (appendonly=true, orientation=column, compresstype=quicklz) DISTRIBUTED RANDOMLY';
	execute 'CREATE temp TABLE '||tempouttable1||' ( alpinepldagenera bigint , '||docidcolumn||' bigint , '|| doccontentcolumn||' bigint[], alpinepldainfo plda_assign_topics ) WITH (appendonly=true, orientation=column, compresstype=quicklz) DISTRIBUTED RANDOMLY';
	sql:= 'insert into '||tempouttable||' ( select 1  , '||docidcolumn||' , '|| doccontentcolumn||' ,
	alpine_plda_first( array_upper('|| doccontentcolumn||',1),'||topicnumber||') as alpinepldainfo from '||content_table||' ) ';
	execute sql;
	sql := 'select sum((alpinepldainfo).topic_count) as alldoctopic,alpine_plda_count('|| doccontentcolumn||',(alpinepldainfo).assign,'||topicnumber||','||wordnumber||') as wordtopic from '|| tempouttable||' where '||docidcolumn||' is not null and '|| doccontentcolumn||' is not null ';
		for myrecord in execute sql loop
			alldoctopic:=myrecord.alldoctopic;
			wordtopic:=myrecord.wordtopic;
		end loop;
		geneoutputtable:=tempouttable;
		geneinputtable:=tempouttable1;
	for tempiteration in 2.. iteration_number loop
		if mod(tempiteration,2) = 0
		then 
			geneoutputtable:=tempouttable1;
			geneinputtable:=tempouttable;
		else 
			geneoutputtable:=tempouttable;
			geneinputtable:=tempouttable1;
		end if;
		execute ' TRUNCATE TABLE '||geneoutputtable;
		execute 'insert into '||geneoutputtable||' ( select '||tempiteration||'  , '||docidcolumn||' , 
		'|| doccontentcolumn||' ,	alpine_plda_gene( '|| doccontentcolumn||',array['||array_to_string(alldoctopic,',')||'],array['||array_to_string(wordtopic,',')||'],(alpinepldainfo).assign,(alpinepldainfo).topic_count,'||alpha||','||beta||',
		'||wordnumber||','||topicnumber||') as alpinepldainfo from '||geneinputtable||') ';
		
			sql := 'select sum((alpinepldainfo).topic_count) as alldoctopic,alpine_plda_count('|| doccontentcolumn||',(alpinepldainfo).assign,'||topicnumber||','||wordnumber||') as wordtopic from '|| geneoutputtable||' where '||docidcolumn||' is not null and '|| doccontentcolumn||' is not null ';
		for myrecord in execute sql loop
			alldoctopic:=myrecord.alldoctopic;
			wordtopic:=myrecord.wordtopic;
		end loop;
	end loop;
		
	execute 'create table '||outtable||outappendonlystring||' as select '||docidcolumn||'  , '|| doccontentcolumn||' ,   (alpinepldainfo).assign  from '|| geneoutputtable||' where alpinepldagenera = '||iteration_number||outdistributestring;
	execute 'create table '||doctopictable||doctopicoutappendonlystring||' as select '||docidcolumn||'  , '|| doccontentcolumn||' ,  (alpinepldainfo).topic_count   from '|| geneoutputtable||' where alpinepldagenera = '||iteration_number||doctopicoutdistributestring;

	sql:='CREATE  TABLE '||topicouttable||topicoutappendonlystring||'  as  select diccontent[ss.i], alpine_plda_word_topic(array['||array_to_string(wordtopic,',')||'],'||topicnumber||',ss.i) 
		from  (select '||diccontentcolumn||' as diccontent from '||dictable||' limit 1   ) as foo,  (select generate_series(1,'||wordnumber||') i) as ss  '||topicoutdistributestring;
	execute sql;
RETURN 1;

END;

 $BODY$
  LANGUAGE plpgsql VOLATILE;
  
  
CREATE OR REPLACE FUNCTION alpine_plda_predict(doc bigint[], gtopic_count bigint[], wordtopic bigint[], topicnumber bigint, wordnumber bigint,
             alpha float, beta float,iteraternumber bigint)
RETURNS plda_assign_topics AS $$
DECLARE
    result plda_assign_topics;
BEGIN
    result := alpine_plda_first(array_upper(doc,1), topicnumber);
    FOR i in 1..iteraternumber LOOP
        result := alpine_plda_gene(doc,gtopic_count,wordtopic,(result).assign,(result).topic_count,alpha,beta,wordnumber,topicnumber);
        END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION  alpine_miner_plda_predict( 
	modeltable text,
	content_table text , 
	docidcolumn text, 
	doccontentcolumn text, 
	alpha float , 
	beta float , 
	topicnumber bigint , 
	iteration_number bigint , 
	dictable text,
	diccontentcolumn text,
	temptable text,
	docouttable text,
	appendonlystring text,
	distributestring text,
	doctopictable text,
	doctopicappendonlystring text,
	doctopicdistributestring text
)
  RETURNS double precision AS
$BODY$
DECLARE 
	i bigint;
	j bigint;
	k bigint;
	wordnumber bigint;
	tempnumber bigint:=0;
	tempiteration bigint;
	sql text;
	wordtopic bigint[];--each word counts in every topic
	alldoctopic  bigint[];--counts for each topic
	myrecord record;
	doccontent bigint[];
	diccontent text[];
	docwordcontent text[];

	
BEGIN

	
	for tempnumber in 1..topicnumber loop
		alldoctopic[tempnumber]:=0;
	end loop;
	
	
	execute 'select  array_upper('||diccontentcolumn||',1) as wordnumber from '||dictable||' limit 1 ' into wordnumber;
	sql := 'select alpine_plda_count('|| doccontentcolumn||',assign,'||topicnumber||','||wordnumber||') as wordtopic from '|| modeltable||' where '||docidcolumn||' is not null and '|| doccontentcolumn||' is not null ';
	for myrecord in execute sql loop
		wordtopic:=myrecord.wordtopic;
	end loop;
	i:=array_upper(wordtopic,1);
	for tempnumber in 1..i loop
		alldoctopic[mod((tempnumber-1),topicnumber::bigint)+1]:=alldoctopic[mod(tempnumber-1,topicnumber::bigint)+1]+wordtopic[tempnumber];
	end loop;
	

	
	
	execute 'create temp table '||temptable ||' as select '||docidcolumn||' ,'|| doccontentcolumn||',alpine_plda_predict('||doccontentcolumn||',array['||array_to_string(alldoctopic,',')||']
		,array['||array_to_string(wordtopic,',')||'],'|| topicnumber||','||wordnumber||','||alpha||','||beta||','||iteration_number||') as alpinepldainfo  from '||content_table||' where '||docidcolumn||' is not null and '|| doccontentcolumn||' is not null  DISTRIBUTED RANDOMLY';
	

	execute 'CREATE  TABLE '||docouttable|| appendonlystring ||' as select  '||docidcolumn||'  , '|| doccontentcolumn||' ,  (alpinepldainfo).assign as alpinepldaassign  from '||temptable||distributestring;
	execute   ' create table '||doctopictable||  doctopicappendonlystring ||'  as select '||docidcolumn||'  , '|| doccontentcolumn||' ,  (alpinepldainfo).topic_count as alpinepldatopic  from  '||temptable||doctopicdistributestring;





RETURN 1;

END;

 $BODY$
  LANGUAGE plpgsql VOLATILE;
  
CREATE OR REPLACE FUNCTION alpine_miner_randomforest_inittra(schemaname text, tablename text, stamp text, dependcolumn text)
  RETURNS integer AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 1;
BEGIN
	execute 'Drop table IF EXISTS '||schemaname||'."pnew'||stamp||'"';
	execute 'Drop table IF EXISTS'||schemaname||'."dn' || stamp || '"';
	execute 'Create  table '||schemaname||'."dn' || stamp || '" 
                      as select *
                    from '||schemaname||'.'|| tablename ||' where '||dependcolumn||' is not null DISTRIBUTED RANDOMLY';
  
	execute  'select count(*)   from '||schemaname||'."dn' || stamp || '"'
	into rownumber;
	peoso := 1.0 / rownumber;

	execute 'Create  table '||schemaname||'."pnew' || stamp || '" 
                      as select *,
                    row_number()over(order by 1) alpine_randomforest_id,
                    '||peoso||' alpine_randomforest_peoso, 
                    row_number()over()*'||peoso||' alpine_randomforest_totalpeoso 
                    from '||schemaname||'."dn' || stamp || '" DISTRIBUTED BY (alpine_randomforest_id) ';


			
RETURN rownumber;
end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;
  
  
  
  
  
CREATE OR REPLACE FUNCTION  alpine_miner_randomforest_sample(schemaname text, tablename text, stamp text, partsize integer)
  RETURNS text AS
$BODY$
DECLARE 
	rownumber integer;
	randomnumber float;
	myrecord record;
	partnumber integer;
	--partsize   integer;
	tempstring text;
	splitpeoso double precision[];
	maxpeoso   double precision;
	i          integer;
BEGIN
	execute 'select count(*) from '||schemaname||'.'||tablename into rownumber;
	execute ' select max(alpine_randomforest_totalpeoso)  from '||schemaname||'.'||tablename into maxpeoso;
	if partsize>= rownumber
	then 
		partnumber:=1;
	else 
		if mod(rownumber ,partsize)=0
		then
			partnumber:= rownumber/partsize;
		else 
			partnumber:=trunc(rownumber/partsize)+1;
		end if;
	end if;
 	execute 'Drop table IF EXISTS '||schemaname||'."s'||stamp||'"';
	execute 'Drop table IF EXISTS "r'||stamp||'"';
	execute 'create temp table "r'||stamp||'" as select '||maxpeoso||'*random() as alpine_miner_randomforest_r from '||schemaname||'.'||tablename||' order by alpine_miner_randomforest_r DISTRIBUTED by (alpine_miner_randomforest_r)';
	if partnumber=1 
	then
		execute 'create table '||schemaname||'."s'||stamp||'" as select * from '||schemaname||'.'||tablename||' join  "r'||stamp||'" on 
		'||schemaname||'.'||tablename||'.alpine_randomforest_totalpeoso >= "r'||stamp||'".alpine_miner_randomforest_r  and '||schemaname||'.'||tablename||'.alpine_randomforest_peoso > 
		('||schemaname||'.'||tablename||'.alpine_randomforest_totalpeoso-"r'||stamp||'".alpine_miner_randomforest_r ) DISTRIBUTED BY (alpine_randomforest_id)';
	else 
		--partsize:=trunc(rownumber*percent);
		tempstring:=' select alpine_randomforest_totalpeoso as peoso from '||schemaname||'.'||tablename||' where mod(alpine_randomforest_id,'||partsize||')=0 order by peoso';

		i:=1;
		splitpeoso[i]:=0;
		for myrecord in execute tempstring loop
			i:=i+1;
			splitpeoso[i]:=myrecord.peoso;
		 
		end loop;

		
		if splitpeoso[i]!=maxpeoso
		then
			i:=i+1;
			splitpeoso[i]:=maxpeoso;
	 
		end if;
		i:=1;
		tempstring:='create table '||schemaname||'."s'||stamp||'" as select * from  ( select * from '||schemaname||'.'||tablename||' 
			where alpine_randomforest_totalpeoso>'||splitpeoso[i]||' and  alpine_randomforest_totalpeoso<='||splitpeoso[i+1]||') as foo'||i||' join (select * from "r'||stamp||'" where alpine_miner_randomforest_r 
			>'||splitpeoso[i]||' and  alpine_miner_randomforest_r<='||splitpeoso[i+1]||') as foor'||i||' on foo'||i||'.alpine_randomforest_totalpeoso >=foor'||i||'.alpine_miner_randomforest_r and foo'||i||'.alpine_randomforest_peoso > 
		(foo'||i||'.alpine_randomforest_totalpeoso-foor'||i||'.alpine_miner_randomforest_r) ';
		tempstring:=tempstring||' DISTRIBUTED by (alpine_randomforest_id)';
		execute tempstring;
		 
 		for i in 2..partnumber loop
			tempstring:= '  insert into  '||schemaname||'."s'||stamp||'"   select * from ( select * from '||schemaname||'.'||tablename||' 
  			where alpine_randomforest_totalpeoso>'||splitpeoso[i]||' and  alpine_randomforest_totalpeoso<='||splitpeoso[i+1]||') as foo'||i||' join (select * from "r'||stamp||'" where alpine_miner_randomforest_r 
  			>'||splitpeoso[i]||' and  alpine_miner_randomforest_r<='||splitpeoso[i+1]||') as foor'||i||' on foo'||i||'.alpine_randomforest_totalpeoso >=foor'||i||'.alpine_miner_randomforest_r and foo'||i||'.alpine_randomforest_peoso > 
 			(foo'||i||'.alpine_randomforest_totalpeoso-foor'||i||'.alpine_miner_randomforest_r) ';
		 
			execute tempstring;
		end loop;
 	end if;
	tempstring = 's'||stamp;
	RETURN tempstring; 
end;
 $BODY$
  LANGUAGE plpgsql VOLATILE;
  
  
  
  
  
  
  
  
CREATE OR REPLACE FUNCTION alpine_miner_randomforest_initpre(tablename text, stamp text, dependcolumn text, infor text[],istemp boolean)
  RETURNS void AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 0;
BEGIN
	execute 'Drop table IF EXISTS "id'||stamp||'"';
	execute 'Create temp table "id'||stamp||'" as select *,row_number()over() alpine_randomforest_id from '||tablename||' DISTRIBUTED BY (alpine_randomforest_id)';
	execute 'Drop table IF EXISTS  '||tablename;
	if istemp=true
	then execute 'Create temp table '||tablename||' as select * from "id'||stamp||'" DISTRIBUTED BY (alpine_randomforest_id)';
	else
	execute 'Create  table '||tablename||' as select * from "id'||stamp||'" DISTRIBUTED BY (alpine_randomforest_id)';
	end if ;
	execute 'Drop  table IF EXISTS "to'||stamp||'"';
	


 tempstring:='update '||tablename||' set "C('||infor[1]||')"=0';

  
  for i in 2 .. alpine_miner_get_array_count(infor) loop
    tempstring := tempstring||', "C(' || infor[i] ||')"=0';
  
  end loop;

	execute tempstring;
end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;


  
  CREATE OR REPLACE FUNCTION alpine_miner_randomforest_prere(tablename text, dependcolumn text, infor text[], isnumeric int)
  RETURNS void AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	sql1 text;
	sql2 text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 0;
	err float;
BEGIN
	classnumber:= alpine_miner_get_array_count(infor);
	
	sql:= 'update '||tablename||' set  "P('||dependcolumn||')" = CASE';
	sql2 := '(';

	i:=classnumber;
	while i>1 loop
	sql2 :=sql2||'  "C('||infor[i]||')" ,';
	
	i:=i-1;
	end loop;
	sql2:=sql2||' "C('||infor[1]||')")';
	for i in 1..alpine_miner_get_array_count(infor) loop
		sql := sql||' WHEN "C('||infor[i]||')"=greatest'||sql2||' THEN ';
		if isnumeric = 1 then
			sql := sql || infor[i];
		else
			sql := sql||''''||infor[i]||'''';
		end if;
	end loop;
	sql := sql||' END ';
	execute sql;


end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;


-- Function: alpine_miner_adaboost_prestep(text, text, text, double precision, text[])

-- DROP FUNCTION alpine_miner_adaboost_prestep(text, text, text, double precision, text[]);

CREATE OR REPLACE FUNCTION alpine_miner_randomforest_prestep(tablename text, temptable text, dependcolumn text,   infor text[])
  RETURNS double precision AS
$BODY$
DECLARE 
	rownumber integer;
	classnumber integer;
	sql text;
	sql1 text;
	sql2 text;
	peoso float;
	totalpeoso float;
	tempstring text;
	classstring text[];
	i integer:= 0;
	err float;
	
BEGIN	
	sql:='update ' || tablename || '  set "C(' ||
                      infor[1] || ')"= ' || tablename || '."C(' || infor[1] ||
                      ')"+ '||temptable||'."C('||infor[1]||')" ';
			for i in 2..alpine_miner_get_array_count(infor) loop
			sql:=sql||' ,"C('||infor[i]||')"= '||tablename||'."C('||infor[i]||')"+ 
				'||temptable||'."C('||infor[i]||')" '  ;
					
	end loop;

		sql:=sql||'from '||temptable||'  where '||tablename||'.alpine_randomforest_id = '||temptable||'.alpine_randomforest_id';
	execute sql;
RETURN 1;
end;

 $BODY$
  LANGUAGE plpgsql VOLATILE;



  
  
CREATE OR REPLACE FUNCTION alpine_miner_nn_ca_o(weight float[], column_names float[], input_range float[], input_base float[], hidden_node_number integer[], hidden_layer_number integer,  output_range float, output_base float, output_node_number integer, normalize boolean , floatal_label boolean)
    RETURNS float []
    AS 'alpine_miner', 'alpine_miner_nn_ca_o'
    LANGUAGE C immutable ;
CREATE OR REPLACE FUNCTION alpine_miner_nn_ca_change(weight float[], column_names float[], input_range float[], input_base float[], hidden_node_number integer[], hidden_layer_number integer,  output_range float, output_base float, output_node_number integer, normalize boolean , floatal_label boolean, label float, set_size int)
    RETURNS float []
    AS 'alpine_miner', 'alpine_miner_nn_ca_change'
    LANGUAGE C immutable ;

    CREATE OR REPLACE FUNCTION alpine_miner_kmeans_distance_loop(sample double precision[], data double precision[], k integer, distancemode integer)
  RETURNS integer AS
'alpine_miner', 'alpine_miner_kmeans_distance_loop'
  LANGUAGE 'c' IMMUTABLE;
  
  CREATE OR REPLACE FUNCTION alpine_miner_kmeans_distance_result(sample double precision[], data double precision[], k integer, distancemode integer)
  RETURNS double precision AS
'alpine_miner', 'alpine_miner_kmeans_distance_result'
  LANGUAGE 'c' IMMUTABLE;

CREATE OR REPLACE FUNCTION alpine_miner_nb_ca_deviance  (nominal_column_names text[], nominal_columns_mapping_count int[], nominal_columns_mapping text[],nominal_columns_probability float[],dependent_column text, dependent_column_mapping text[], dependent_column_probability float[], numerical_columns float[], numerical_columns_probability float[])
    RETURNS float
    AS 'alpine_miner', 'alpine_miner_nb_ca_deviance'
    LANGUAGE C immutable ;

CREATE OR REPLACE FUNCTION alpine_miner_nb_ca_confidence(nominal_column_names text[], nominal_columns_mapping_count int[], nominal_columns_mapping text[],nominal_columns_probability float[],dependent_column_mapping text[], dependent_column_probability float[], numerical_columns float[], numerical_columns_probability float[])
    RETURNS float []
    AS 'alpine_miner', 'alpine_miner_nb_ca_confidence'
    LANGUAGE C immutable ;

CREATE OR REPLACE FUNCTION alpine_miner_nb_ca_prediction(confidence_column float[], dependent_column_mapping text[])
    RETURNS text
    AS 'alpine_miner', 'alpine_miner_nb_ca_prediction'
    LANGUAGE C immutable ;

CREATE OR REPLACE FUNCTION alpine_miner_dot_product( float[], float[] ) 
	RETURNS float
	AS 'alpine_miner', 'alpine_miner_dot_product'
	LANGUAGE C IMMUTABLE;

CREATE OR REPLACE FUNCTION alpine_miner_has_novel_product( float[], float[] ) 
	RETURNS int
	AS 'alpine_miner', 'alpine_miner_has_novel_product'
	LANGUAGE C IMMUTABLE;
CREATE OR REPLACE FUNCTION alpine_miner_replacementsampling(weight double precision)    
  RETURNS SETOF integer AS
$BODY$
declare i integer ;
begin
	i:=1;
	return next i;
	i:=0;
	if weight >=1 then
		for i in 1 ..floor(weight) loop
			return next 0;
			 
		end loop;
	end if;

	
	if weight-floor(weight)>random()
	then
		return next i;
	end if;
	return ;
	end;
 $BODY$
  LANGUAGE 'plpgsql' VOLATILE;


CREATE OR REPLACE FUNCTION alpine_miner_repsampling_genedata(weight bigint)    
  RETURNS SETOF integer AS
$BODY$
declare i integer ;
begin
	i:=1;
	 
	for i in 1 ..weight loop
		return next 0;
	end loop;
	
	return ;
	end;
 $BODY$
  LANGUAGE 'plpgsql' VOLATILE;
  
  
  
  
  
  CREATE OR REPLACE FUNCTION alpine_miner_repadasampling(weight double precision )    
  RETURNS SETOF double precision AS
$BODY$
declare i integer ;
begin
	--i:=1;
	return next 0;
	--i:=0;
	if weight >=1 then
		for i in 1 ..floor(weight) loop
			return next 1+random();
			 
		end loop;
	end if;

	
	if weight-floor(weight)>random()
	then
		return next 1+random();
	end if;
	return ;
	end;
 $BODY$
  LANGUAGE 'plpgsql' VOLATILE;
CREATE OR REPLACE FUNCTION alpine_miner_svd_l(input_matrix text,p_name text, q_name text,  m_column text, n_column text, value_column text, num_features integer, init_val double precision)
  RETURNS double precision[] AS
$BODY$
DECLARE 
    j int := 0;
    sql text := '';
    float_temp float := 0;
    alpha float[] ;
    beta float[] ;
BEGIN

    sql := 'CREATE  TEMP TABLE '||p_name||'  WITH (appendonly=true) as select ' || m_column || ' as m_column , 1 as n_column, ' || '0.1' || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY (m_column);
    CREATE TEMP TABLE '||q_name||'  WITH (appendonly=true) as select ' || n_column || ' as n_column , 1 as m_column, ' || '0.1' || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY (n_column); 
    CREATE TEMP TABLE '||p_name||'1 as select ' || m_column || ' as m_column , ' || '0.1' || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY (m_column);
    CREATE TEMP TABLE '||q_name||'1 as select ' || n_column || ' as n_column , ' || '0.1' || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY (n_column); ';

    execute sql;

    j := 1;
    execute 'INSERT INTO '||q_name||'1 SELECT distinct ' || n_column || ', '||(init_val)||' FROM ' || input_matrix || ' where ' || n_column || ' is not null';
    execute 'INSERT INTO '||q_name||' SELECT n_column, 1, val FROM '||q_name||'1'; 

    while (j <=  num_features) loop
        if (j = 1) then
            execute 'insert into  '||p_name||'1  select a.' || m_column || ', sum(a.'|| value_column ||' * '||q_name||'.val) from ' || input_matrix || ' a join '||q_name||' on a.' || n_column || ' = '||q_name||'.n_column and '||q_name||'.m_column = 1 and a.'|| value_column ||' is not null  group by a.'|| m_column ;
        else
            execute 'insert into '||p_name||'1  select  foo.m_column , foo.val - ('||beta[j - 1]||') * '||p_name||'.val  from  (select a.' || m_column || ' as m_column, sum(a.'|| value_column ||' * '||q_name||'.val) as val from ' || input_matrix || ' a join '||q_name||' on a.'||n_column|| ' = '||q_name||'.n_column and '||q_name||'.m_column = '||j||' and a.'|| value_column ||' is not null  group by a.'|| m_column ||') as foo join '||p_name||'  on foo.m_column  = '||p_name||'.m_column  and  '||p_name||'.n_column = '||(j- 1);
        end if;
        execute  'select sqrt(sum(val * val)) from '||p_name||'1 ' into float_temp;
        alpha[j] := float_temp;
	if alpha[j] = 0
	then 
                beta[j] = 0;
		exit;
        end if;

        execute 'INSERT INTO '||p_name||' SELECT  m_column,'||(j)||', (1.0*val/'||alpha[j]||') FROM '||p_name||'1'; 
	execute 'TRUNCATE TABLE '||q_name||'1';
        execute 'insert into '||q_name||'1 select foo.n_column , foo.val - ('||alpha[j]||') * '||q_name||'.val from  (select a.' || n_column || 'as n_column,  sum(a.'|| value_column ||' * '||p_name||'.val) as  val from ' || input_matrix || ' a join '||p_name||' on a.' || m_column || ' = '||p_name||'.m_column and '||p_name||'.n_column = '||j||'  and a.'|| value_column ||' is not null  group by a.'|| n_column ||') as foo join '||q_name||'  on foo.n_column  = '||q_name||'.n_column and '||q_name||'.m_column = '||j;

        execute  'select sqrt(sum(val * val)) from '||q_name||'1 ' into float_temp;
        beta[j] := float_temp;
	if beta[j] = 0
	then 
		exit;
        end if;
	if (j != num_features) then
	        execute 'INSERT INTO '||q_name||' SELECT n_column, '||(j + 1)||', (1.0*val/'||beta[j]||') FROM '||q_name||'1'; 
	end if;
        sql := 'TRUNCATE TABLE '||p_name||'1';
        execute sql;
        j := j + 1;
    end loop;
    return array_cat(alpha, beta);        
END;
$BODY$
  LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION alpine_miner_svd(
input_matrix text,
col_name text,
row_name text,
value text,
num_features int,
ORIGINAL_STEP float , 
SPEEDUP_CONST float,
FAST_SPEEDUP_CONST float,
SLOWDOWN_CONST float,
NUM_ITERATIONS int,
MIN_NUM_ITERATIONS int,
MIN_IMPROVEMENT float,
IMPROVEMENT_REACHED int,
INIT_VALUE float,
EARLY_TEMINATE int,
matrix_u text,
matrix_v text,
drop_u int,
drop_v int
)
RETURNS int AS
$BODY$
DECLARE 
    ORIGINAL_STEP_ADJUST float := 0; 
    error float :=0;
    old_error float :=0;
    keep_ind int := 1;
    SD_ind int := 1;

    feature_x float := 0;
    feature_y float := 0;
    i int := 0;
    j int := 0;
    cells int := 0;
    sql text := '';
    step float := 0;
    imp_reached int := 0;
BEGIN

    -- Find sizes of the input and number of elements in the input
    execute 'SELECT count(distinct ' || col_name || ') AS c FROM ' || input_matrix || ' where ' || col_name || ' is not null' into feature_x; 
    execute 'SELECT count(distinct ' || row_name || ') AS c FROM ' || input_matrix || ' where ' || row_name || ' is not null'into feature_y; 
    execute 'SELECT count(*) AS c FROM ' || input_matrix into cells; 
    
    ORIGINAL_STEP_ADJUST := ORIGINAL_STEP/(feature_x+feature_y)/(cells);

    sql := '';
    if(drop_u = 1) then
        sql := 'DROP TABLE IF EXISTS '||matrix_u||';';
    end if;
    sql := sql || 'CREATE TABLE '||matrix_u||' as select 1 as alpine_feature , ' || col_name || ', ' || value || ' from ' || input_matrix || ' where 0 = 1 DISTRIBUTED BY (alpine_feature);';
    if(drop_v = 1) then
        sql := sql||'DROP TABLE IF EXISTS '|| matrix_v||';';
    end if;
    sql := sql || 'CREATE TABLE '||matrix_v||' as select ' || row_name || ' , 1 as alpine_feature, ' || value || ' from ' || input_matrix || ' where 0 =  1 DISTRIBUTED BY (' || row_name || ');
    DROP TABLE IF EXISTS e1;
    CREATE TEMP TABLE e1  WITH (appendonly=true) as select ' || row_name || ' as row_num , ' || col_name || ' as col_num , ' || value || ' as val from ' || input_matrix || ' where 0 = 1 DISTRIBUTED BY (row_num, col_num);
    DROP TABLE IF EXISTS e2;
    CREATE TEMP TABLE e2  WITH (appendonly=true) as select ' || row_name || ' as row_num , ' || col_name || ' as col_num , ' || value || ' as val from ' || input_matrix || ' where 0 = 1 DISTRIBUTED BY (row_num, col_num);
    DROP TABLE IF EXISTS S1;
    CREATE TEMP TABLE S1  WITH (appendonly=true) as select ' || col_name || ' as col_num , ' || value || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY ( col_num);
    DROP TABLE IF EXISTS S2;
    CREATE TEMP TABLE S2  WITH (appendonly=true) as select ' || col_name || ' as col_num , ' || value || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY ( col_num);
    DROP TABLE IF EXISTS D1;
    CREATE TEMP TABLE D1  WITH (appendonly=true) as select ' || row_name || ' as row_num , ' || value || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY ( row_num);
    DROP TABLE IF EXISTS D2;
    CREATE TEMP TABLE D2 WITH (appendonly=true) as select ' || row_name || ' as row_num , ' || value || ' as val from ' || input_matrix || ' where 0 = 1
     DISTRIBUTED BY ( row_num);
    DROP TABLE IF EXISTS e;
    CREATE TEMP TABLE e  WITH (appendonly=true) as select ' || row_name || ' as row_num , ' || col_name || ' as col_num , ' || value || ' as val from ' || input_matrix || ' where 0 = 1 DISTRIBUTED BY (row_num, col_num);';

    --raise notice '0';
    execute sql;
    --raise notice '1';
    execute 'INSERT INTO e1 SELECT ' || row_name || ', ' || col_name || ', ' || value || ' FROM ' || input_matrix ;
    j := 1;
    while (j <=  num_features) loop
        
    	--raise notice 'j:%', j;
        sql := 'TRUNCATE TABLE S1;
        TRUNCATE TABLE S2;
        TRUNCATE TABLE D1;
        TRUNCATE TABLE D2;';
        execute sql;
        
        execute 'INSERT INTO S1 SELECT distinct ' || col_name || ', '||(INIT_VALUE)||' FROM ' || input_matrix || ' where ' || col_name || ' is not null';
        execute 'INSERT INTO D1 SELECT distinct ' || row_name || ', '||(INIT_VALUE)||' FROM ' || input_matrix || ' where ' || row_name || ' is not null';
        SD_ind := 1;
        i := 0;
        step := ORIGINAL_STEP_ADJUST;
        imp_reached := 0;
        
        while ( true ) loop

            i := i + 1;
    	    --raise notice 'i:%', i;

            sql := '   TRUNCATE TABLE e'; 
            execute sql;
        
            execute 'INSERT INTO e SELECT a.row_num, a.col_num, a.val-b.val*c.val FROM e'||(keep_ind)||' AS a, S'||(SD_ind)||' AS b, D'||(SD_ind)||' AS c WHERE a.row_num=c.row_num AND a.col_num=b.col_num';
            old_error := error;
            execute 'SELECT sqrt(sum(val*val)) AS c FROM e' into error;
            if(((abs(error - old_error) < MIN_IMPROVEMENT) and (i >= MIN_NUM_ITERATIONS) and ((error < MIN_IMPROVEMENT) or (not (IMPROVEMENT_REACHED = 1)) or (imp_reached = 1))) or (NUM_ITERATIONS < i)) then
                exit;
            end if;
               
            if((abs(error - old_error) >= MIN_IMPROVEMENT) and (old_error > 0)) then
                   imp_reached := 1;
            end if;
               
            if((error > old_error) and (old_error != 0)) then
                error := 0;
                step := step*SLOWDOWN_CONST;
                SD_ind := SD_ind%2+1;
            else
                if(sqrt((error - old_error)*(error - old_error)) < .1*MIN_IMPROVEMENT) then
                    step := step*FAST_SPEEDUP_CONST;
                else
                    step := step*SPEEDUP_CONST;
                end if;
                   
                execute 'TRUNCATE TABLE S'||(SD_ind%2+1);
                execute 'TRUNCATE TABLE D'||(SD_ind%2+1);
            
                execute 'INSERT INTO S'||(SD_ind%2+1)||' SELECT a.col_num, avg(b.val)+sum(a.val*c.val)*'||(step)||' FROM e as a, S'||(SD_ind)||' as b, D'||(SD_ind)||' as c WHERE a.col_num = b.col_num AND a.row_num=c.row_num GROUP BY a.col_num';
                execute 'INSERT INTO D'||(SD_ind%2+1)||' SELECT a.row_num, avg(c.val)+sum(a.val*b.val)*'||(step)||' FROM e as a, S'||(SD_ind)||' as b, D'||(SD_ind)||' as c WHERE a.col_num = b.col_num AND a.row_num=c.row_num GROUP BY a.row_num';    
                SD_ind := SD_ind%2+1;
            end if;
        end loop;

        execute 'TRUNCATE TABLE e'||(keep_ind%2+1);
        execute 'INSERT INTO e'||(keep_ind%2+1)||' SELECT a.row_num, a.col_num, (a.val-b.val*c.val) FROM e'||(keep_ind)||' as a, S'||(SD_ind)||' as b, D'||(SD_ind)||' as c WHERE a.col_num = b.col_num AND a.row_num=c.row_num';
        
        keep_ind := keep_ind%2+1;
        execute 'INSERT INTO '||matrix_u||' SELECT '||(j)||', col_num, val FROM S'||(SD_ind); 
        execute 'INSERT INTO '||matrix_v||' SELECT row_num, '||(j)||', val FROM D'||(SD_ind); 
        if((error < MIN_IMPROVEMENT) and (EARLY_TEMINATE = 1)) then
            exit;
	end if;
        
        error := 0;
        j := j + 1;
    end loop;
    return 1;        
END;
$BODY$
  LANGUAGE 'plpgsql' ;
drop type IF EXISTS alpine_miner_svm_model cascade;
CREATE TYPE alpine_miner_svm_model AS (
       inds int, -- number of individuals processed
       cum_err float8, -- cumulative error
       epsilon float8, -- the size of the epsilon tube around the hyperplane, adaptively adjusted by algorithm
       rho float8, -- classification margin
       b float8, -- classifier offset
       nsvs int, -- number of support vectors
       ind_dim int, -- the dimension of the individuals
       weights float8[], -- the weight of the support vectors
       individuals float8[]--, -- the array of support vectors, represented as a 1-D array
--       kernel_oid oid -- OID of kernel function
);


CREATE OR REPLACE FUNCTION alpine_miner_svm_predict_sub(int,int,float8[],float8[],float8[],int, int, float8) RETURNS float8
AS 'alpine_miner', 'alpine_miner_svm_predict_sub' LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION alpine_miner_svs_predict(svs alpine_miner_svm_model, ind float8[], kernel_type int, degree int, gamma float8)
RETURNS float8 AS $$
SELECT alpine_miner_svm_predict_sub($1.nsvs, $1.ind_dim, $1.weights, $1.individuals, $2, $3, $4, $5);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION
alpine_miner_svm_reg_update(svs alpine_miner_svm_model, ind FLOAT8[], label FLOAT8, eta FLOAT8, nu FLOAT8, slambda FLOAT8, kernel_type int, degree int, gamma float8)
RETURNS alpine_miner_svm_model AS 'alpine_miner', 'alpine_miner_svm_reg_update' LANGUAGE C STRICT;

CREATE AGGREGATE alpine_miner_svm_reg_agg(float8[], float8, float8, float8, float8, int, int, float8) (
       sfunc = alpine_miner_svm_reg_update,
       stype = alpine_miner_svm_model,
       initcond = '(0,0,0,0,1,0,0,{},{})'
);

CREATE OR REPLACE FUNCTION
alpine_miner_svm_cls_update(svs alpine_miner_svm_model, ind FLOAT8[], label FLOAT8, eta FLOAT8, nu FLOAT8, kernel_type int, degree int, gamma float8)
RETURNS alpine_miner_svm_model AS 'alpine_miner', 'alpine_miner_svm_cls_update' LANGUAGE C STRICT;


CREATE AGGREGATE alpine_miner_svm_cls_agg(float8[], float8, float8, float8, int, int, float8) (
       sfunc = alpine_miner_svm_cls_update,
       stype = alpine_miner_svm_model,
       initcond = '(0,0,0,0,1,0,0,{},{})'
);

CREATE OR REPLACE FUNCTION
alpine_miner_svm_nd_update(svs alpine_miner_svm_model, ind FLOAT8[],  eta FLOAT8, nu FLOAT8, kernel_type int, degree int, gamma float8)
RETURNS alpine_miner_svm_model AS 'alpine_miner', 'alpine_miner_svm_nd_update' LANGUAGE C STRICT;

CREATE AGGREGATE alpine_miner_svm_nd_agg(float8[], float8, float8, int, int, float8) (
       sfunc = alpine_miner_svm_nd_update,
       stype = alpine_miner_svm_model,
       initcond = '(0,0,0,0,0,0,0,{},{})'
);

CREATE OR REPLACE FUNCTION alpine_miner_online_sv_reg(table_name text, ind text, label text,wherestr text,  kernel_type int, degree int, gamma float, eta FLOAT8, slambda FLOAT8, nu FLOAT8) 
RETURNS alpine_miner_svm_model AS $$
DECLARE
	svs alpine_miner_svm_model ;
	sql text;
BEGIN
	sql := 'select (model).inds, (model).cum_err, (model).epsilon, (model).rho, (model).b, (model).nsvs, (model).ind_dim, (model).weights,(model).individuals from (select  alpine_miner_svm_reg_agg('||ind||'::float8[], '||label||'::float8,' || eta || ',' || nu || ',' || slambda || ','|| kernel_type|| ','|| degree|| ','|| gamma|| ') as model from ' || table_name||' where  '||wherestr||' ) a';
	execute sql into svs.inds, svs.cum_err, svs.epsilon, svs.rho, svs.b, svs.nsvs, svs.ind_dim, svs.weights, svs.individuals;
	return svs;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alpine_miner_online_sv_cl(table_name text, ind text, label text, wherestr text, kernel_type int, degree int, gamma float, eta FLOAT8, nu FLOAT8) 
RETURNS alpine_miner_svm_model AS $$
DECLARE
	svs alpine_miner_svm_model ;
	sql text;
BEGIN
--alpine_miner_svm_cls_update(svs alpine_miner_svm_model, ind FLOAT8[], label FLOAT8, eta FLOAT8, nu FLOAT8, kernel_type int, degree int, gamma float8)
	sql := 'select (model).inds, (model).cum_err, (model).epsilon, (model).rho, (model).b, (model).nsvs, (model).ind_dim, (model).weights,(model).individuals from (select  alpine_miner_svm_cls_agg('||ind||'::float8[], '||label||'::float8,' || eta || ',' ||nu ||','|| kernel_type|| ',' ||degree||','|| gamma|| ') as model from ' || table_name||' where '||wherestr||' ) a';
	execute sql into svs.inds, svs.cum_err, svs.epsilon, svs.rho, svs.b, svs.nsvs, svs.ind_dim, svs.weights, svs.individuals;
	return svs;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION alpine_miner_online_sv_nd(table_name text, ind text, wherestr text, kernel_type int, degree int, gamma float, eta FLOAT8, nu FLOAT8) 
RETURNS alpine_miner_svm_model AS $$
DECLARE
	svs alpine_miner_svm_model ;
	sql text;
BEGIN
--alpine_miner_svm_nd_update(svs alpine_miner_svm_model, ind FLOAT8[],  eta FLOAT8, nu FLOAT8, kernel_type int, degree int, gamma float8)
	sql := 'select (model).inds, (model).cum_err, (model).epsilon, (model).rho, (model).b, (model).nsvs, (model).ind_dim, (model).weights,(model).individuals from (select  alpine_miner_svm_nd_agg('||ind||'::float8[],' || eta || ',' || nu ||  ', '|| kernel_type|| ', '|| degree|| ', '|| gamma|| ') as model from ' || table_name||' where  '||wherestr||'  ) a';
	execute sql into svs.inds, svs.cum_err, svs.epsilon, svs.rho, svs.b, svs.nsvs, svs.ind_dim, svs.weights, svs.individuals;
	return svs;
END
$$ LANGUAGE plpgsql;


