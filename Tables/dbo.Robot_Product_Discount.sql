CREATE TABLE [dbo].[Robot_Product_Discount]
(
[ROBO_RBID] [bigint] NULL,
[RBPR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[TARF_CODE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OFF_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OFF_PRCT] [real] NULL,
[REMN_TIME] [datetime] NULL,
[ACTV_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OFF_DESC] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_RBPD]
ON [dbo].[Robot_Product_Discount]
AFTER INSERT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for trigger here
    MERGE dbo.Robot_Product_Discount T USING (SELECT
            *
        FROM INSERTED) S
    ON (T.ROBO_RBID = S.ROBO_RBID
        AND T.CODE = S.CODE)
    WHEN MATCHED
        THEN UPDATE
            SET T.CRET_BY = UPPER(SUSER_NAME())
               ,T.CRET_DATE = GETDATE()
               ,T.CODE =
                CASE S.CODE
                    WHEN 0 THEN dbo.GNRT_NVID_U()
                    ELSE S.CODE
                END
               ,T.RBPR_CODE =
                CASE ISNULL(S.RBPR_CODE, 0)
                    WHEN 0 THEN (SELECT
                                rp.CODE
                            FROM dbo.Robot_Product rp
                            WHERE rp.ROBO_RBID = S.ROBO_RBID
                            AND rp.TARF_CODE = S.TARF_CODE)
                    ELSE S.RBPR_CODE
                END
               ,T.TARF_CODE =
                CASE ISNULL(S.TARF_CODE, 0)
                    WHEN 0 THEN (SELECT
                                rp.TARF_CODE
                            FROM dbo.Robot_Product rp
                            WHERE rp.ROBO_RBID = S.ROBO_RBID
                            AND rp.CODE = S.RBPR_CODE)
                    ELSE S.TARF_CODE
                END;
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
CREATE TRIGGER [dbo].[CG$AUPD_RBPD]
   ON  [dbo].[Robot_Product_Discount]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Robot_Product_Discount T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE SET 
         T.MDFY_BY = UPPER(SUSER_NAME()),
         T.MDFY_DATE = GETDATE();
         
END
GO
ALTER TABLE [dbo].[Robot_Product_Discount] ADD CONSTRAINT [PK_RBPD] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Product_Discount] ADD CONSTRAINT [FK_RBPD_RBPR] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE])
GO
ALTER TABLE [dbo].[Robot_Product_Discount] ADD CONSTRAINT [FK_RBPD_ROBO] FOREIGN KEY ([ROBO_RBID]) REFERENCES [dbo].[Robot] ([RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'ایا تخفیف همچنان فعال یا غیر فعال می باشد', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_Discount', 'COLUMN', N'ACTV_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'توضیحات تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_Discount', 'COLUMN', N'OFF_DESC'
GO
EXEC sp_addextendedproperty N'MS_Description', N'درصد تخفیف', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_Discount', 'COLUMN', N'OFF_PRCT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'نوع تخفیف
فروش ویژه
شگفت انگیز
', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_Discount', 'COLUMN', N'OFF_TYPE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'مدت زمان باقیمانده برای فروش شگفت انگیز', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_Discount', 'COLUMN', N'REMN_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'کد کالا', 'SCHEMA', N'dbo', 'TABLE', N'Robot_Product_Discount', 'COLUMN', N'TARF_CODE'
GO
