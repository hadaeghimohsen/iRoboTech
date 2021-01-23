CREATE TABLE [dbo].[Service_Robot_Product_Find_Best_Price]
(
[SRBT_SERV_FILE_NO] [bigint] NULL,
[SRBT_ROBO_RBID] [bigint] NULL,
[RBPR_CODE] [bigint] NULL,
[CODE] [bigint] NOT NULL,
[CHAT_ID] [bigint] NULL,
[PRIC] [bigint] NULL,
[ONLN_SHOP] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WEB_SITE] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOP_ADRS] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SHOP_NAME] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CRET_DATE] [datetime] NULL,
[MDFY_BY] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MDFY_DATE] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Product_Find_Best_Price] ADD CONSTRAINT [PK_Service_Robot_Product_Find_Best_Price] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Service_Robot_Product_Find_Best_Price] ADD CONSTRAINT [FK_Service_Robot_Product_Find_Best_Price_Robot_Product] FOREIGN KEY ([RBPR_CODE]) REFERENCES [dbo].[Robot_Product] ([CODE]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Service_Robot_Product_Find_Best_Price] ADD CONSTRAINT [FK_Service_Robot_Product_Find_Best_Price_Service_Robot] FOREIGN KEY ([SRBT_SERV_FILE_NO], [SRBT_ROBO_RBID]) REFERENCES [dbo].[Service_Robot] ([SERV_FILE_NO], [ROBO_RBID]) ON DELETE CASCADE
GO
