SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_ITMV_F]
(
	@X XML
)
RETURNS NVARCHAR(4000)
AS
BEGIN
	DECLARE @Rbid BIGINT
	       ,@ChatId BIGINT
	       ,@PkId BIGINT
	       ,@TempItem VARCHAR(100);
	
	SELECT @Rbid = @X.query('TemplateItemToText').value('(TemplateItemToText/@rbid)[1]', 'BIGINT')
	      ,@ChatId = @X.query('TemplateItemToText').value('(TemplateItemToText/@chatid)[1]', 'BIGINT')
	      ,@PkId = @X.query('TemplateItemToText').value('(TemplateItemToText/@pkid)[1]', 'BIGINT')
	      ,@TempItem = @X.query('TemplateItemToText').value('(TemplateItemToText/@tempitem)[1]', 'VARCHAR(100)');
	
	RETURN 
	   CASE @TempItem
	      -- اطلاعات عمومی پرونده مشتریان
	      WHEN '{SRBT_EXPR_DATE}' THEN (SELECT dbo.GET_MTOS_U(sr.EXPR_DATE) FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_SRPB_RWNO}' THEN (SELECT CAST(sr.SRPB_RWNO AS NVARCHAR(30)) FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_COMP_NAME}' THEN (SELECT sr.COMP_NAME FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_REGN_CODE}' THEN (SELECT sr.REGN_CODE FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_REF_CHAT_ID}' THEN (SELECT CAST(sr.REF_CHAT_ID AS NVARCHAR(30)) FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_CORD_X}' THEN (SELECT CAST(sr.CORD_X AS NVARCHAR(30)) FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_CORD_Y}' THEN (SELECT CAST(sr.CORD_Y AS NVARCHAR(30)) FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_OTHR_CELL_PHON}' THEN (SELECT sr.OTHR_CELL_PHON FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_CHAT_ID}' THEN (SELECT CAST(sr.CHAT_ID AS NVARCHAR(30)) FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_REGN_PRVN_CODE}' THEN (SELECT sr.REGN_PRVN_CODE FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_REAL_LAST_NAME}' THEN (SELECT sr.REAL_LAST_NAME FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_JOIN_DATE}' THEN (SELECT dbo.GET_MTOS_U(sr.JOIN_DATE) FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_REAL_FRST_NAME}' THEN (SELECT sr.REAL_FRST_NAME FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_REGN_PRVN_CNTY_CODE}' THEN (SELECT sr.REGN_PRVN_CNTY_CODE FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_SRBT_DESC}' THEN (SELECT sr.SRBT_DESC FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_SERV_ADRS}' THEN (SELECT sr.SERV_ADRS FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_CELL_PHON}' THEN (SELECT sr.CELL_PHON FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_NAME}' THEN (SELECT sr.NAME FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_NATL_CODE}' THEN (SELECT sr.NATL_CODE FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_INST_USER_NAME}' THEN (SELECT sr.INST_USER_NAME FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)
         WHEN '{SRBT_OTHR_SERV_ADDR}' THEN (SELECT sr.OTHR_SERV_ADDR FROM dbo.Service_Robot sr WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId)         
         WHEN '{SRBT_STAT}' THEN (SELECT d.DOMN_DESC FROM dbo.Service_Robot sr, dbo.[D$ACTV] d WHERE sr.ROBO_RBID = @Rbid AND sr.CHAT_ID = @ChatId AND d.VALU = sr.STAT)
         
         -- اطلاعات اینستاگرام فروشنده
         WHEN '{RINS_NAME}' THEN (SELECT TOP 1 i.NAME FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_GNDR_TYPE}' THEN (SELECT TOP 1 d.DOMN_DESC FROM Robot_Instagram i, dbo.[D$SXDC] d WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002' AND d.VALU = i.GNDR_TYPE)
         WHEN '{RINS_BUSN_ZIP_CODE}' THEN (SELECT TOP 1 i.BUSN_ZIP_CODE FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_PASS_WORD}' THEN (SELECT TOP 1 i.PASS_WORD FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_BIOG_DESC}' THEN (SELECT TOP 1 i.BIOG_DESC FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_BUSN_PHON}' THEN (SELECT TOP 1 i.BUSN_PHON FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_BUSN_CONT_MTOD}' THEN (SELECT TOP 1 i.BUSN_CONT_MTOD FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_PAGE_LINK}' THEN (SELECT TOP 1 i.PAGE_LINK FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_EMAL_ADRS}' THEN (SELECT TOP 1 i.EMAL_ADRS FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_USER_NAME}' THEN (SELECT TOP 1 i.USER_NAME FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_FULL_NAME}' THEN (SELECT TOP 1 i.FULL_NAME FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_IMAG_PROF_PATH}' THEN (SELECT TOP 1 i.IMAG_PROF_PATH FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_WEB_LINK}' THEN (SELECT TOP 1 i.WEB_LINK FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_BUSN_POST_ADRS}' THEN (SELECT TOP 1 i.BUSN_POST_ADRS FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_URL}' THEN (SELECT TOP 1 i.URL FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_CELL_PHON}' THEN (SELECT TOP 1 i.CELL_PHON FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         WHEN '{RINS_STAT}' THEN (SELECT TOP 1 d.DOMN_DESC FROM Robot_Instagram i, dbo.[D$ACTV] d WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002' AND d.VALU = i.STAT)
         WHEN '{RINS_BUSN_LOCT_NAME}' THEN (SELECT TOP 1 i.BUSN_LOCT_NAME FROM Robot_Instagram i WHERE i.ROBO_RBID = @Rbid AND i.PAGE_OWNR_TYPE = '002' AND i.STAT = '002')
         
         -- اطلاعات اینستاگرام مشتریان
         WHEN '{RINF_FOLW_TYPE}' THEN (SELECT TOP 1 d.DOMN_DESC FROM Robot_Instagram_Follow f, dbo.[D$FLTP] d WHERE f.INST_PKID = @Pkid AND d.VALU = f.FOLW_TYPE)         
         WHEN '{RINF_CTGY_DESC}' THEN (SELECT TOP 1 f.CTGY_DESC FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         WHEN '{RINF_BIOG_DESC}' THEN (SELECT TOP 1 f.BIOG_DESC FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         WHEN '{RINF_URL}' THEN (SELECT TOP 1 f.URL FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         WHEN '{RINF_FULL_NAME}' THEN (SELECT TOP 1 f.FULL_NAME FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         WHEN '{RINF_EMAL_ADRS}' THEN (SELECT TOP 1 f.EMAL_ADRS FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         WHEN '{RINF_INST_PKID}' THEN (SELECT TOP 1 CAST(f.INST_PKID AS NVARCHAR(30)) FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         WHEN '{RINF_USER_NAME}' THEN (SELECT TOP 1 f.[USER_NAME] FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         WHEN '{RINF_CHAT_ID}' THEN (SELECT TOP 1 CAST(f.CHAT_ID AS NVARCHAR(30)) FROM Robot_Instagram_Follow f WHERE f.INST_PKID = @Pkid)
         
         -- متغییر های عمومی
         WHEN '{DATE}' THEN (SELECT dbo.GET_MTOS_U(GETDATE()))
         WHEN '{TIME}' THEN (SELECT dbo.GET_TIME_U(GETDATE()))
         WHEN '{DATE_TIME}' THEN (SELECT dbo.GET_MTST_U(GETDATE()))
	   END;
END
GO
