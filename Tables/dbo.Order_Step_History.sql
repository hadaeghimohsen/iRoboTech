CREATE TABLE [dbo].[Order_Step_History]
(
[ORDR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[RWNO] [smallint] NULL,
[ORDR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[STAT_DATE] [datetime] NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL
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
CREATE TRIGGER [dbo].[CG$AINS_ODSH]
   ON  [dbo].[Order_Step_History]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   -- Insert statements for trigger here
   MERGE dbo.Order_Step_History T
   USING (SELECT * FROM Inserted) S
   ON (t.ORDR_CODE = s.ORDR_CODE AND 
       t.CODE = s.CODE)
   WHEN MATCHED THEN 
      UPDATE SET
         T.CRET_BY = UPPER(SUSER_NAME()),
         T.CRET_DATE = GETDATE(),
         t.STAT_DATE = GETDATE(),
         T.CODE = CASE s.CODE WHEN 0 THEN dbo.GNRT_NVID_U() ELSE s.CODE END,
         T.RWNO = (SELECT ISNULL(MAX(os.RWNO), 0) + 1 FROM dbo.Order_Step_History os WHERE os.ORDR_CODE = s.ORDR_CODE);
END
GO
ALTER TABLE [dbo].[Order_Step_History] ADD CONSTRAINT [PK_ODSH] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Order_Step_History] ADD CONSTRAINT [FK_ODSH_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
