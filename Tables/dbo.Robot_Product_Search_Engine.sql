CREATE TABLE [dbo].[Robot_Product_Search_Engine]
(
[RBPR_CODE] [bigint] NULL,
[ROSE_SGID] [bigint] NULL,
[CODE] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Robot_Product_Search_Engine] ADD CONSTRAINT [PK_Robot_Product_Search_Engine] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
