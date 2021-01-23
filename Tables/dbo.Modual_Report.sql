CREATE TABLE [dbo].[Modual_Report]
(
[CODE] [bigint] NOT NULL,
[MDUL_NAME] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[MDUL_DESC] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SECT_NAME] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SECT_DESC] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RWNO] [int] NULL,
[RPRT_DESC] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RPRT_PATH] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SHOW_PRVW] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Modual_Report_SHOW_PRVW] DEFAULT ('002'),
[DFLT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Modual_Report_DFLT] DEFAULT ('001'),
[PRNT_AFTR_PAY] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STAT] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Modual_Report_STAT] DEFAULT ('002'),
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
CREATE TRIGGER [dbo].[CG$AINS_MDRP]
   ON  [dbo].[Modual_Report]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @ErrorMessage NVARCHAR(MAX);
	DECLARE @Code BIGINT
	       ,@MdulName VARCHAR(11)
	       ,@SectName VARCHAR(11)
	       ,@Rwno INT
	       ,@RprtDesc NVARCHAR(200)
	       ,@RprtPath VARCHAR(MAX)
	       ,@Dflt VARCHAR(3)
	       ,@PrntAftrPay VARCHAR(3)
	       ,@Stat VARCHAR(3);
	       
	BEGIN TRY
	   BEGIN TRAN CG$AINS_MDRP
         DECLARE C$AINS_MDRP CURSOR FOR
            SELECT Code, Mdul_Name, Rprt_Desc, Rprt_Path, Dflt, Stat, Sect_Name, Prnt_Aftr_Pay FROM INSERTED;
         
         OPEN C$AINS_MDRP;
         FNFC$AINS_MDRP:
         FETCH NEXT FROM C$AINS_MDRP INTO @Code, @MdulName, @RprtDesc, @RprtPath, @Dflt, @Stat, @SectName, @PrntAftrPay;
         
         IF @@FETCH_STATUS <> 0
            GOTO CDC$AINS_MDRP;
         
         IF 1 <= (SELECT COUNT(CODE) FROM Modual_Report WHERE ISNULL(CODE, 0) <> 0 AND MDUL_NAME = @MdulName AND SECT_NAME = @SectName AND RPRT_PATH = @RprtPath )
            RAISERROR(N'برای فرم جاری قبلا همین فایل گزارش اضافه شده است', 16, 1);

         IF @Dflt = '002'
            UPDATE Modual_Report
               SET DFLT = '001'
             WHERE MDUL_NAME = @MdulName;
                      
         UPDATE Modual_Report
            SET CRET_BY = UPPER(SUSER_NAME())
               ,CRET_DATE = GETDATE()
               ,RWNO = (SELECT ISNULL(MAX(RWNO), 0) + 1 FROM Modual_Report WHERE MDUL_NAME = @MdulName AND SECT_NAME = @SectName)
               ,STAT = COALESCE(@Stat, '002')
               ,DFLT = COALESCE(@Dflt, '001')
               ,PRNT_AFTR_PAY = COALESCE(@PrntAftrPay, '001')
               ,CODE = dbo.GNRT_NWID_U()
           WHERE MDUL_NAME = @MdulName
             AND CODE = @Code;
         
         GOTO FNFC$AINS_MDRP;
         CDC$AINS_MDRP:
         CLOSE C$AINS_MDRP;
         DEALLOCATE C$AINS_MDRP;
      COMMIT TRAN CG$AINS_MDRP;
   END TRY
   
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('local','C$AINS_MDRP')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$AINS_MDRP')) > -1
         BEGIN
          CLOSE C$AINS_MDRP
         END
       DEALLOCATE C$AINS_MDRP
      END
      
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CG$AINS_MDRP;
   END CATCH
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  TRIGGER [dbo].[CG$AUPD_MDRP]
   ON  [dbo].[Modual_Report]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @ErrorMessage NVARCHAR(MAX);
	DECLARE @Code BIGINT
	       ,@MdulName VARCHAR(11)
	       ,@SectName VARCHAR(11)
	       ,@Rwno INT
	       ,@RprtDesc NVARCHAR(200)
	       ,@RprtPath VARCHAR(MAX)
	       ,@Dflt VARCHAR(3)
	       ,@PrntAftrPay VARCHAR(3)
	       ,@Stat VARCHAR(3);
	       
	BEGIN TRY
	   BEGIN TRAN CG$AUPD_MDRP
         DECLARE C$AUPD_MDRP CURSOR FOR
            SELECT Code, Mdul_Name, Rprt_Desc, Rprt_Path, Dflt, Stat, Sect_Name, Prnt_Aftr_Pay FROM INSERTED;
         
         OPEN C$AUPD_MDRP;
         FNFC$AUPD_MDRP:
         FETCH NEXT FROM C$AUPD_MDRP INTO @Code, @MdulName, @RprtDesc, @RprtPath, @Dflt, @Stat, @SectName, @PrntAftrPay;
         
         IF @@FETCH_STATUS <> 0
            GOTO CDC$AUPD_MDRP;
         
         IF 1 <= (SELECT COUNT(CODE) FROM Modual_Report WHERE CODE <> @Code AND MDUL_NAME = @MdulName AND SECT_NAME = @SectName AND RPRT_PATH = @RprtPath)
            RAISERROR(N'برای فرم جاری قبلا همین فایل گزارش اضافه شده است', 16, 1);
         
         IF @Dflt = '002'
            UPDATE Modual_Report
               SET DFLT = '001'
             WHERE MDUL_NAME = @MdulName
               AND CODE <> @Code;
         
         UPDATE Modual_Report
            SET MDFY_BY = UPPER(SUSER_NAME())
               ,MDFY_DATE = GETDATE()               
           WHERE CODE = @Code;
         
         GOTO FNFC$AUPD_MDRP;
         CDC$AUPD_MDRP:
         CLOSE C$AUPD_MDRP;
         DEALLOCATE C$AUPD_MDRP;
      COMMIT TRAN CG$AUPD_MDRP;
   END TRY
   
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('local','C$AUPD_MDRP')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$AUPD_MDRP')) > -1
         BEGIN
          CLOSE C$AUPD_MDRP
         END
       DEALLOCATE C$AUPD_MDRP
      END
      
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN CG$AUPD_MDRP;
   END CATCH
END
GO
ALTER TABLE [dbo].[Modual_Report] ADD CONSTRAINT [PK_MDRP] PRIMARY KEY CLUSTERED  ([CODE]) ON [PRIMARY]
GO
