SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[CRET_PMSG_U]
(
	@X XML
)
RETURNS NVARCHAR(Max)
AS
BEGIN
	DECLARE @PrjbCode BIGINT
	       ,@OrdrCode BIGINT
	       ,@OrdtRwno BIGINT;
	
	SELECT @PrjbCode = @X.query('//Message').value('(Message/@prjbcode)[1]', 'BIGINT')
	      ,@OrdrCode = @X.query('//Message').value('(Message/@ordrcode)[1]', 'BIGINT')
	      ,@OrdtRwno = @X.query('//Message').value('(Message/@ordtrwno)[1]', 'BIGINT')
	
	/*VALU	DOMN_DESC
001	پیشنهادات
002	نظرسنجی
003	شکایات
004	سفارشات
005	LIKE
006	پرسش
007	پاسخ
008	تجربیات
009   Upload
010   معرفی*/
	
	DECLARE @Message NVARCHAR(MAX);
	SELECT @Message = 
	       N'📬 *ارجاع پیام به شما' + CHAR(10) + 
	       --N'👤 ' + /*ISNULL(s.NAME, s.CHAT_ID)*/ CAST(s.CHAT_ID AS NVARCHAR(30)) + ' - ' + ISNULL(sv.FRST_NAME, '') + ' - ' + ISNULL(sv.LAST_NAME, '') + CHAR(10) + 
	       --N'📞 ' + CASE WHEN s.CELL_PHON IS NULL THEN N'شماره تلفن ثبت نشده' ELSE s.CELL_PHON END + CHAR(10) +
          N'👈 ' + Op.DOMN_DESC + CHAR(10) + 
          N'✉️ ' + 
            CASE 
               WHEN o.ORDR_TYPE IN ( '010' ) THEN d.ORDR_CMNT + N' * ' + d.ORDR_DESC + N' * ' + CAST(ISNULL(d.NUMB, 0) AS NVARCHAR(10))
               WHEN o.ORDR_TYPE IN ('012','017', '018', '019') THEN d.ORDR_CMNT + N' * ' + CHAR(10) + N'[ شماره ارجاع ] : *' + CAST(o.CODE AS NVARCHAR(30)) + N'*' + CHAR(10) + N'[ کد سیستم ] *' + CAST(o.ORDR_TYPE_NUMB AS VARCHAR(30)) + N' - ' + o.ORDR_TYPE + N'*'+ CHAR(10) + CHAR(10) + d.ORDR_DESC 
               ELSE d.ORDR_DESC
            END
	  FROM dbo.Personal_Robot_Job_Order p, 
          dbo.[Order] o, 
          dbo.Order_Detail d, 
          dbo.Service_Robot s,
          dbo.Service sv,
          dbo.[D$ORDT] op
   WHERE p.ORDR_CODE = o.CODE
     AND o.CODE = d.ORDR_CODE
     AND o.SRBT_SERV_FILE_NO = s.SERV_FILE_NO
     AND o.SRBT_ROBO_RBID = s.ROBO_RBID
     AND p.Cust_CHAT_ID = s.CHAT_ID	  
     AND o.ORDR_TYPE = Op.VALU
     AND s.SERV_FILE_NO = sv.FILE_NO
	  AND p.PRJB_CODE = @PrjbCode	  
	  AND o.CODE = @OrdrCode
	  AND d.RWNO = @OrdtRwno;
   
   RETURN @Message;
END
GO
