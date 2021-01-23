CREATE TABLE [dbo].[Robot_Product_Download]
(
[RBPR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RWNO] [int] NULL,
[SORC_FILE_PATH] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TRGT_FILE_PATH] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DNLD_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_ID] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_DESC] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AINS_RPDL]
   ON [dbo].[Robot_Product_Download]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   DECLARE C$AINS_RPDL CURSOR FOR
      SELECT i.CODE
        FROM Inserted i;
   
   DECLARE @Code BIGINT;
   
   OPEN [C$AINS_RPDL];
   L$Loop$C$AINS_RPDL:
   FETCH [C$AINS_RPDL] INTO @Code;
   
   IF @@FETCH_STATUS <> 0
      GOTO L$EndLoop$C$AINS_RPDL;
   
   MERGE dbo.Robot_Product_Download T
   USING (SELECT * FROM Inserted i WHERE i.CODE = @Code) S
   ON (t.RBPR_CODE = s.RBPR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(S.STAT, '002'),
         T.DNLD_TYPE = ISNULL(S.DNLD_TYPE, '002'),
         T.RWNO = (SELECT ISNULL(MAX(d.RWNO), 0) + 1 FROM dbo.Robot_Product_Download d WHERE d.RBPR_CODE = s.RBPR_CODE),
         t.TARF_CODE = (
            SELECT rp.TARF_CODE
              FROM dbo.Robot_Product rp
             WHERE rp.CODE = s.RBPR_CODE
         );
   
   GOTO L$Loop$C$AINS_RPDL;
   L$EndLoop$C$AINS_RPDL:
   CLOSE [C$AINS_RPDL];
   DEALLOCATE [C$AINS_RPDL];
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE TRIGGER [dbo].[CG$AUPD_RPDL]
   ON [dbo].[Robot_Product_Download]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   MERGE dbo.Robot_Product_Download T
   USING (SELECT * FROM Inserted i) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
   
END
GO
ALTER TABLE [dbo].[Robot_Product_Download] ADD CONSTRAINT [PK_RPDL] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Product_Download] ADD CONSTRAINT [FK_RPDL_RBPR] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
