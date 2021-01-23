CREATE TABLE [dbo].[Robot_Product_Limited]
(
[RBPR_CODE] [bigint] NULL,
[RLCG_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE_DNRM] [bigint] NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RPLM]
   ON  [dbo].[Robot_Product_Limited]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Product_Limited T
   USING (SELECT * FROM Inserted) S
   ON (t.RLCG_CODE = s.RLCG_CODE AND 
       t.RBPR_CODE = s.RBPR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.STAT = ISNULL(S.STAT, '002'),
         T.TARF_CODE_DNRM = (
            SELECT rp.TARF_CODE
              FROM dbo.Robot_Product rp
             WHERE rp.CODE = s.RBPR_CODE
         );
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
CREATE TRIGGER [dbo].[CG$AUPD_RPLM]
   ON  [dbo].[Robot_Product_Limited]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Product_Limited T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
END
GO
ALTER TABLE [dbo].[Robot_Product_Limited] ADD CONSTRAINT [PK_RPLM] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Product_Limited] ADD CONSTRAINT [FK_RPLM_RBPR] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Robot_Product_Limited] ADD CONSTRAINT [FK_RPLM_RLCG] FOREIGN KEY ([RLCG_CODE]) REFERENCES [dbo].[Robot_Limited_Commodity_Group] ([CODE])
GO
