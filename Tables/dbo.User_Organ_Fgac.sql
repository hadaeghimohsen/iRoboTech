CREATE TABLE [dbo].[User_Organ_Fgac]
(
[FGA_CODE] [bigint] NOT NULL,
[ORGN_OGID] [bigint] NULL,
[SYS_USER] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[REC_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_UGFG_REC_STAT] DEFAULT ('002'),
[VALD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_UGFG_VALD_TYPE] DEFAULT ('002'),
[CRET_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create TRIGGER [dbo].[CG$AINS_UGFG]
   ON  [dbo].[User_Organ_Fgac]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   -- Insert statements for trigger here
   MERGE dbo.User_Organ_Fgac T
   USING (SELECT * FROM INSERTED) S
   ON (T.ORGN_OGID = S.ORGN_OGID AND
       T.SYS_USER  = S.SYS_USER  AND
       T.REC_STAT  = S.REC_STAT AND
       T.REC_STAT  = '002')
   WHEN MATCHED THEN
      UPDATE 
         SET CRET_BY   = UPPER(SUSER_NAME())
            ,CRET_DATE = GETDATE()
            ,FGA_CODE  = dbo.GNRT_NWID_U();
   
END
;
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CG$AUPD_UGFG]
   ON  [dbo].[User_Organ_Fgac]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	/*SET NOCOUNT ON;
   IF EXISTS(
      SELECT *
        FROM INSERTED S, User_Organ_Fgac T
       WHERE S.FGA_CODE = T.FGA_CODE
         AND T.REC_STAT = '001' -- غیر فعال
         AND T.VALD_TYPE = '001' -- غیرقابل دیدن
   )
   BEGIN
      RAISERROR( N'اطلاعات غیرفعال و غیرقابل دیدن قابل ویرایش شدن نیستن' , 16, 1);
      RETURN;
   END
   
   ELSE IF EXISTS(
      SELECT *
        FROM DELETED S
       WHERE S.REC_STAT = '001' -- غیر فعال
         AND S.VALD_TYPE = '002' -- غیرقابل دیدن
   )
   BEGIN
      UPDATE DBO.User_Organ_Fgac
         SET VALD_TYPE = '001'
            ,REC_STAT  = '001'
       WHERE FGA_CODE IN (SELECT FGA_CODE FROM DELETED);
   END*/
   
   -- Insert statements for trigger here
   MERGE dbo.User_Organ_Fgac T
   USING (SELECT * FROM INSERTED) S
   ON (T.Orgn_Ogid           = S.Orgn_Ogid AND
       T.REC_STAT            = '002'       AND
       T.VALD_TYPE           = S.VALD_TYPE AND
       T.FGA_CODE            = S.FGA_CODE)
   WHEN MATCHED THEN
      UPDATE 
         SET MDFY_BY   = UPPER(SUSER_NAME())
            ,MDFY_DATE = GETDATE();
   
END
;
GO
ALTER TABLE [dbo].[User_Organ_Fgac] ADD CONSTRAINT [PK_UGFG] PRIMARY KEY CLUSTERED  ([FGA_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[User_Organ_Fgac] ADD CONSTRAINT [FK_UGFG_ORGN] FOREIGN KEY ([ORGN_OGID]) REFERENCES [dbo].[Organ] ([OGID]) ON DELETE CASCADE
GO
