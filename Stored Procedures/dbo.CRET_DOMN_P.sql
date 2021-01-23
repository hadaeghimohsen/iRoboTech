SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[CRET_DOMN_P] 
AS
begin
   declare c$domain cursor for
   select distinct code from dbo.app_domain;
   declare @code varchar(20);
   declare @statement varchar(4000);
   
   open c$domain;
   l$nextrow:
   fetch next from c$domain into @code;
   
   if @@FETCH_STATUS <> 0
      goto l$endloop;
   
   set @statement = '[dbo].[d$' + substring(@code, 3, len(@code)) + ']';
   if  exists (select * from sys.views where object_id = object_id(@statement))
   begin
      set @statement = 'DROP VIEW [dbo].[D$' + SUBSTRING(@code, 3, LEN(@code)) +']';
      exec sp_sqlexec @statement;
   end
   set @statement = 'CREATE VIEW dbo.D$' + SUBSTRING(@code, 3, LEN(@code)) + ' AS SELECT VALU, DOMN_DESC FROM APP_DOMAIN a, iProject.DataGuard.[User] u WHERE A.REGN_LANG = ISNULL(U.REGN_LANG, ''054'') AND UPPER(u.USERDB) = UPPER(SUSER_NAME()) AND CODE = ''' + @code + '''';
   exec sp_sqlexec @statement;
   goto l$nextrow;
  
   l$endloop:
   close c$domain;
   deallocate c$domain;   
end;
GO
