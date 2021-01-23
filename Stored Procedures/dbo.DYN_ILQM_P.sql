SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DYN_ILQM_P]
	@X XML,
	@XRet XML OUTPUT
AS
BEGIN
	BEGIN TRY
	BEGIN TRAN [T$DYN_ILQM_P];
	   DECLARE @Rbid BIGINT
	          ,@MnusMuid BIGINT;
	   
	   SELECT @Rbid = @X.query('//Robot').value('(Robot/@rbid)[1]', 'BIGINT')
	         ,@MnusMuid = @X.query('//Menu_Ussd').value('(Menu_Ussd/@muid)[1]', 'BIGINT');
	   
	   SET @XRet = '';

	   DECLARE @Muid BIGINT
	          ,@UssdCode VARCHAR(250)
	          ,@DestType VARCHAR(3)
	          ,@PathText VARCHAR(250)
	          ,@CmndText VARCHAR(250)
	          ,@ParmText NVARCHAR(250)
	          ,@Xtemp XML
	          ,@CnctAcntApp VARCHAR(3)
	          ,@AcntAppType VARCHAR(3);	   
	   SELECT @CnctAcntApp = CNCT_ACNT_APP
	         ,@AcntAppType = ACNT_APP_TYPE
	     FROM dbo.Robot
	    WHERE RBID = @Rbid;
	   
	   DECLARE C$Menus CURSOR FOR 
	      SELECT mu.MUID, mu.USSD_CODE, mu.DEST_TYPE, mu.PATH_TEXT, mu.CMND_TEXT, mu.PARM_TEXT
	        FROM dbo.Menu_Ussd mu
	       WHERE mu.ROBO_RBID = @Rbid
	         AND mu.MNUS_MUID = @MnusMuid
	         AND mu.MENU_TYPE = '003' -- Dynamic Inline query
	         AND mu.STAT = '002'
	       ORDER BY mu.ORDR;	   
	   
	   OPEN [C$Menus];
	   L$Loop1:
	   FETCH [C$Menus] INTO @Muid, @UssdCode, @DestType, @PathText, @CmndText, @ParmText;
	   
	   IF @@FETCH_STATUS <> 0
	      GOTO L$EndLoop1;
	   
	   /*
	      000   تخفیف های گروهی  => showprodoffall
	      001	تحفیف شگفت انگیز => showprodofftimer
         002	تخفیف فروش ویژه  => showprodoffspecsale
         003	تخفیف شب یلدا    => showprodoffyalda
         004	تخفیف جمعه سیاه  => showprodoffblackfriday
         005	تخفیف آخر سال    => showprodoffendofyear
         006	تخفیف عید نوروز  => showprodoffnorouz
	   */
	   -- بررسی اینکه حالا این منو چه خروجی باید ایجاد کند
      IF @CnctAcntApp = '002' -- اتصال نرم افزار به سیستم حسابداری
      BEGIN
         IF @AcntAppType = '001' -- نرم افزار مدیریت آرتا
         BEGIN
            SET @Xtemp = (
               SELECT N'./' + @PathText + N';showgpoff-' + CAST(T.CODE AS NVARCHAR(30)) + N'$#' AS '@data'
                     ,ROW_NUMBER() OVER ( ORDER BY T.ROOT_GROP_DESC ) AS '@order'
                     ,N'◀️ ' + T.ROOT_GROP_DESC AS "text()"
                 FROM (
                  SELECT DISTINCT iScsc.dbo.GETC_GEXP_U(ge.CODE) AS CODE, /*ge.GROP_DESC,*/ iScsc.dbo.GET_GEXP_U(ge.CODE) AS ROOT_GROP_DESC
                    FROM dbo.Robot_Product_Discount rpd, iScsc.dbo.Expense e, iScsc.dbo.Group_Expense ge
                   WHERE rpd.ROBO_RBID = @Rbid
                     AND rpd.TARF_CODE = e.ORDR_ITEM
                     AND e.GROP_CODE = ge.CODE
                     AND e.EXPN_STAT = '002' -- کالا فعال باشه
                     AND rpd.ACTV_TYPE = '002' -- تخفیف کالا فعال باشد
                     AND rpd.OFF_TYPE = CASE @CmndText 
                                             WHEN 'showprodoffall' THEN rpd.OFF_TYPE
                                             WHEN 'showprodofftimer' THEN '001'
                                             WHEN 'showprodoffspecsale' THEN '002'
                                             WHEN 'showprodoffyalda' THEN '003'
                                             WHEN 'showprodoffblackfriday' THEN '004'
                                             WHEN 'showprodoffendofyear' THEN '005'
                                             WHEN 'showprodoffnorouz' THEN '006'
                                        END 
                  ) T
                  FOR XML PATH('InlineKeyboardButton')
            );	            
            SET @XRet.modify('insert sql:variable("@Xtemp") as first into (.)[1]');
         END;	         
      END;
	   
	   GOTO L$EndLoop1;
	   L$EndLoop1:
	   CLOSE [C$Menus];
	   DEALLOCATE [C$Menus];
	         
	COMMIT TRAN [T$DYN_ILQM_P];
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX);
	   SET @ErorMesg = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRAN [T$DYN_ILQM_P];
	END CATCH	
END
GO
