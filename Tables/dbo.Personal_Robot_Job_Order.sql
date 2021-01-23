CREATE TABLE [dbo].[Personal_Robot_Job_Order]
(
[PRJB_CODE] [bigint] NULL,
[ORDR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL CONSTRAINT [DF_Personal_Robot_Job_Order_CODE] DEFAULT ((0)),
[ORDR_STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PRBT_CHAT_ID] [bigint] NULL,
[CUST_CHAT_ID] [bigint] NULL,
[ORDR_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_PRJO]
   ON  [dbo].[Personal_Robot_Job_Order]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Personal_Robot_Job_Order T
   USING (SELECT Pr.CHAT_ID AS Prbt_Chat_ID,
                 Sr.CHAT_ID AS Cust_Chat_ID,
                 O.ORDR_TYPE,
                 Prj.CODE AS Prjb_Code,
                 o.Code AS Ordr_Code
            FROM INSERTED I, dbo.Personal_Robot_Job Prj, dbo.Personal_Robot Pr
                ,dbo.[Order] o, dbo.Service_Robot Sr
           WHERE I.Prjb_Code = Prj.CODE
             AND Prj.PRBT_SERV_FILE_NO = Pr.SERV_FILE_NO
             AND Prj.PRBT_ROBO_RBID = Pr.ROBO_RBID 
             AND I.Ordr_Code = o.CODE
             AND o.SRBT_SERV_FILE_NO = Sr.SERV_FILE_NO
             AND O.SRBT_ROBO_RBID = Sr.ROBO_RBID
   ) S
   ON (T.PRJB_CODE = S.Prjb_Code AND
       T.ORDR_CODE = S.Ordr_Code )
   WHEN MATCHED THEN
      UPDATE
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,PRBT_CHAT_ID = S.Prbt_Chat_ID
            ,CUST_CHAT_ID = S.Cust_Chat_ID
            ,ORDR_TYPE = S.ORDR_TYPE
            ,Code = dbo.gnrt_nvid_u();
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
CREATE TRIGGER [dbo].[CG$AUPD_PRJO]
   ON  [dbo].[Personal_Robot_Job_Order]
   AFTER UPDATE   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   MERGE dbo.Personal_Robot_Job_Order T
   USING (SELECT * FROM Inserted) S
   ON (t.CODE = s.CODE)
   WHEN MATCHED THEN
      UPDATE
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();
            
END
GO
ALTER TABLE [dbo].[Personal_Robot_Job_Order] ADD CONSTRAINT [PK_Personal_Robot_Job_Order] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Personal_Robot_Job_Order] ADD CONSTRAINT [FK_Personal_Robot_Job_Order_Personal_Robot_Job] FOREIGN KEY ([PRJB_CODE]) REFERENCES [dbo].[Personal_Robot_Job] ([CODE])
GO
ALTER TABLE [dbo].[Personal_Robot_Job_Order] ADD CONSTRAINT [FK_PRJO_ORDR] FOREIGN KEY ([ORDR_CODE]) REFERENCES [dbo].[Order] ([CODE]) ON DELETE CASCADE
GO
