CREATE TABLE [dbo].[Service_Robot_Upload]
(
[SRBT_SERV_FILE_NO] [bigint] NOT NULL,
[SRBT_ROBO_RBID] [bigint] NOT NULL,
[RWNO] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[FILE_PATH] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_ID] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_TYPE] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RECV_DATE] [datetime] NULL,
[USSD_CODE] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FILE_NAME] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[HOST_NAME] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
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
CREATE TRIGGER [dbo].[CG$AINS_SRUP]
   ON  [dbo].[Service_Robot_Upload]
   AFTER INSERT   
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    MERGE dbo.Service_Robot_Upload T
    USING (SELECT * FROM Inserted) S
    ON(T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
       T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID AND
       T.RWNO = S.RWNO AND
       T.FILE_ID = S.FILE_ID)
    WHEN MATCHED THEN
      UPDATE 
         SET T.CRET_BY = UPPER(SUSER_NAME())
            ,T.CRET_DATE = GETDATE()
            ,T.[HOST_NAME] = HOST_NAME()
            ,T.Rwno = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM dbo.Service_Robot_Upload St WHERE S.SRBT_SERV_FILE_NO = St.SRBT_SERV_FILE_NO AND S.SRBT_ROBO_RBID = St.SRBT_ROBO_RBID);
    
    INSERT INTO dbo.[Order]
	              ( SRBT_SERV_FILE_NO ,
	                SRBT_ROBO_RBID ,
	                SRBT_SRPB_RWNO ,
	                ORDR_TYPE ,
	                STRT_DATE ,
	                ORDR_STAT
	              )
    SELECT SERV_FILE_NO,
           i.SRBT_ROBO_RBID,
           SRPB_RWNO,
           '009',
           GETDATE(),
           '001' -- ثبت مرحله اولیه
      FROM dbo.Service_Robot Sr, inserted i
     WHERE sr.CHAT_ID = i.CHAT_ID
       AND sr.ROBO_RBID = i.SRBT_ROBO_RBID
       and sr.SERV_FILE_NO = i.SRBT_SERV_FILE_NO;
   
   DECLARE @OrdrCode BIGINT
          ,@OrdrType VARCHAR(3)
          ,@ElmnType varchar(3)
          ,@FileId varchar(250)
          ,@RoboRbid bigint;
   
   SELECT @OrdrCode = MAX(CODE),
          @OrdrType = ORDR_TYPE,
          @ElmnType = I.FILE_TYPE,
          @FileId = I.FILE_ID,
          @RoboRbid = i.SRBT_ROBO_RBID
     FROM dbo.[Order] o, dbo.Service_Robot sr, inserted i
    WHERE o.SRBT_SERV_FILE_NO = sr.SERV_FILE_NO
      AND o.SRBT_ROBO_RBID = sr.ROBO_RBID
      --and o.CHAT_ID = sr.CHAT_ID
      AND sr.CHAT_ID = i.CHAT_ID	         
      and sr.ROBO_RBID = i.SRBT_ROBO_RBID
      and sr.SERV_FILE_NO = i.SRBT_SERV_FILE_NO
      AND o.ORDR_TYPE = '009'
      GROUP BY ORDR_TYPE,
               i.FILE_TYPE,
               i.FILE_ID,
               i.SRBT_ROBO_RBID;
   
   select @ElmnType = CASE @ElmnType
                         WHEN '001' THEN '002'
                         WHEN '002' then '003'
                         When '003' then '004'
                         WHEN '004' then '005'
                         when '005' then '006'
                      END;
   
   INSERT dbo.Order_Detail
           ( ORDR_CODE ,
             ELMN_TYPE ,
             ORDR_DESC ,
             NUMB
           )
   VALUES  ( @OrdrCode , -- ORDR_CODE - bigint
             @ElmnType , -- ELMN_TYPE - varchar(3)
             @FileId, -- ORDR_DESC - nvarchar(max)
             0  -- NUMB - int
           );
   Declare @XMessage XML;
   SELECT @XMessage = 
   (
      SELECT @OrdrCode AS '@code'
            ,@RoboRbid AS '@roborbid'
            ,@OrdrType '@type'
      FOR XML PATH('Order'), ROOT('Process')
   )
   EXEC Send_Order_To_Personal_Robot_Job @XMessage;
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
CREATE TRIGGER [dbo].[CG$AUPD_SRUP]
   ON  [dbo].[Service_Robot_Upload]
   AFTER UPDATE 
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
    MERGE dbo.Service_Robot_Upload T
    USING (SELECT * FROM Inserted) S
    ON(T.SRBT_SERV_FILE_NO = S.SRBT_SERV_FILE_NO AND
       T.SRBT_ROBO_RBID = S.SRBT_ROBO_RBID AND
       T.RWNO = S.RWNO AND
       T.FILE_ID = S.FILE_ID)
    WHEN MATCHED THEN
      UPDATE 
         SET T.MDFY_BY = UPPER(SUSER_NAME())
            ,T.MDFY_DATE = GETDATE();            
END
GO
ALTER TABLE [dbo].[Service_Robot_Upload] ADD CONSTRAINT [PK_SRUP] PRIMARY KEY CLUSTERED  ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID], [RWNO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Upload] ADD CONSTRAINT [FK_SRUP_SRRB] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'نام کامپیوتر سرور', 'SCHEMA', N'dbo', 'TABLE', N'Service_Robot_Upload', 'COLUMN', N'HOST_NAME'
GO
