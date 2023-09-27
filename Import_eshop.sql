use P5HPBP1;

declare @date date;
set @date = '20230927'; -- zadat datum 

SELECT
dd.PRODUCTCODE 'code',
'' 'pairCode',
wn.PRODUCTNAME + ' ' + EV.ZEME + ' - è. ' + CAST(CAST(substring(convert(varchar, cal.booknumber), 5, 4) AS INT) AS VARCHAR(5)) + '/' + left(cal.BOOKNUMBER, 4) 'name:cs',
wn.PRODUCTNAME + ' ' + EV.COUNTRY + ' - no. ' + CAST(CAST(substring(convert(varchar, cal.booknumber), 5, 4) AS INT) AS VARCHAR(5)) + '/' + left(cal.BOOKNUMBER, 4) 'name:en',
replace(sysadm.sf_ScsGetCopyPrice(dd.PRODUCTCODE, 'ALAP', 'CZ', 'CZK', dd.PUBLICATIONDATE), '.', ',') 'price',
--     		TC.INTVALUE02 - TC.INTVALUE06 as 'stock',
MAX(SQ.QUANTITY) as 'stock',
'availabilityOutOfStock' =
	CASE
		WHEN dd.PRODUCTCODE in (700, 2340, 9956) THEN 'Na objednávku'
		ELSE 'Na dotaz'
	END,
'Skladem' as 'availabilityInStock',
'freeShipping' =
	CASE
		WHEN sysadm.sf_ScsGetCopyPrice(dd.PRODUCTCODE, 'ALAP', 'CZ', 'CZK', dd.PUBLICATIONDATE) > 1000 THEN '1'
		ELSE '0'
	END,
'visible' as 'productVisibility',
/*'purchasePrice' =
	CASE
		WHEN pc.ISOCURRENCYCODE = 'EUR' THEN convert(varchar,ORIGINATORNETWD3 * 24)
		WHEN pc.ISOCURRENCYCODE = 'GBP' THEN convert(varchar,ORIGINATORNETWD3 * 27)
		WHEN pc.ISOCURRENCYCODE = 'USD' THEN convert(varchar,ORIGINATORNETWD3 * 21)
		ELSE pc.ISOCURRENCYCODE
	END,
pc.ISOCURRENCYCODE,*/
'ean' =
	CASE
		WHEN patindex('% %',iss.BARCODENUMBEROUT) = 0 THEN /*''''*/ + iss.BARCODENUMBEROUT
		ELSE /*''''*/ + LEFT(iss.BARCODENUMBEROUT,patindex('% %',iss.BARCODENUMBEROUT)-1)
	END,
1 as 'ilustracni-fotografieFlagActive'

/*, pc.ORIGINATORNETWD1 as 'purchasePrice'*/--,*

from

(SELECT PRODUCTCODE, PUBLICATIONDATE 
	from HUP_DUEDATE 
	where DUEDATECODE = 'ONSALE' and COMPANYCLIENTNO = 3 and DUEDATETIME = @date) dd
join ASA_WEBPRODUCTNAMES wn 
	on wn.PRODUCTCODE = dd.PRODUCTCODE
join DIS_PUBLICATIONCALENDAR cal 
	on cal.PRODUCTCODE = dd.PRODUCTCODE and cal.PUBLICATIONDATE = dd.PUBLICATIONDATE and cal.DELIVERYPARTNERNO = 0
join CCS_ISSUE iss 
	on iss.PRODUCTCODE = dd.PRODUCTCODE and iss.PUBLICATIONDATE = dd.PUBLICATIONDATE
join CCS_SHIPMENTPOS shp 
	on shp.ISSUERECNO = iss.RECNO
join CCS_SHIPMENT sh 
	on sh.RECNO = shp.SHIPMENTRECNO and sh.RECEIVINGPLACECLIENTNO = 1041
join SCSX_PRICECODE as pc
	on pc.PRODUCTCODE = cal.PRODUCTCODE
join STM_STOCKPRODUCT as SP
	on sp.PRODUCTID = dd.PRODUCTCODE + '/FK/' + convert(varchar, dd.PUBLICATIONDATE, 23)
join STM_STOCKQUANTITY as sq
	on SP.PRODUCTNO = SQ.PRODUCTNO
join
(SELECT 
	REFERENCEID, 
	'ZEME' =
		CASE 
		 WHEN REFERENCEID IN (2538) THEN '(Anglický)'
		 WHEN REFERENCEID IN (10895) THEN '(Èeský)'
		 WHEN VALUE = 'USA' THEN '(Americký)'
		 WHEN VALUE = 'GB' THEN '(Britský)'
		 WHEN VALUE = 'D' THEN '(Nìmecký)'
		 WHEN VALUE = 'F' THEN '(Francouzský)'
		 WHEN VALUE = 'E' THEN '(Španìlský)'
		 WHEN VALUE = 'I' THEN '(Italský)'
		 WHEN VALUE = 'CZ' THEN '(Èeský)'
		 WHEN VALUE = 'RUS' THEN '(Ruský)'
		 WHEN VALUE = 'SVK' THEN '(Slovenský)'
		 ELSE VALUE
		END,
	'COUNTRY' =
		CASE
		 WHEN REFERENCEID IN (2538) THEN '(English)'
		 WHEN REFERENCEID IN (10895) THEN '(Czech)'
		 WHEN VALUE = 'USA' THEN '(American)'
		 WHEN VALUE = 'GB' THEN '(British)'
		 WHEN VALUE = 'D' THEN '(German)'
		 WHEN VALUE = 'F' THEN '(French)'
		 WHEN VALUE = 'E' THEN '(Spanish)'
		 WHEN VALUE = 'I' THEN '(Italian)'
		 WHEN VALUE = 'CZ' THEN '(Czech)'
		 WHEN VALUE = 'RUS' THEN '(Russian)'
		 WHEN VALUE = 'SVK' THEN '(Slovakian)'
		 ELSE VALUE
		END
	FROM HUPX_EXTENDEDVALUE 
	WHERE ITEMKEY = '5004') as EV
	on EV.REFERENCEID = wn.PRODUCTCODE

				/*
left join    TMP_CCSOUTPUT48574    	  as TC
	on dd.PRODUCTCODE = TC.GROUPCODE01 and cal.BOOKNUMBER = TC.INTVALUE01
				*/
	
WHERE dd.PRODUCTCODE NOT IN (10100, 10101, 11602, 10107, 777, 10103, 778, 23, 24, 47) -- deniky
GROUP BY dd.PRODUCTCODE, wn.PRODUCTNAME + ' ' + EV.ZEME + ' - è. ' + CAST(CAST(substring(convert(varchar, cal.booknumber), 5, 4) AS INT) AS VARCHAR(5)) + '/' + left(cal.BOOKNUMBER, 4), dd.PUBLICATIONDATE, ISS.BARCODENUMBEROUT,
wn.PRODUCTNAME + ' ' + EV.COUNTRY + ' - no. ' + CAST(CAST(substring(convert(varchar, cal.booknumber), 5, 4) AS INT) AS VARCHAR(5)) + '/' + left(cal.BOOKNUMBER, 4)          --                 , TC.INTVALUE02 - TC.INTVALUE06
ORDER BY dd.PRODUCTCODE, wn.PRODUCTNAME + ' ' + EV.ZEME + ' - è. ' + CAST(CAST(substring(convert(varchar, cal.booknumber), 5, 4) AS INT) AS VARCHAR(5)) + '/' + left(cal.BOOKNUMBER, 4)


while @@TRANCOUNT > 0
rollback;

------------------------------------------------
/* Tituly, které nejsou v ASA_WEBPRODUCTNAMES */
------------------------------------------------
SELECT 
	dd.PRODUCTCODE 'code',
	'' as 'pairCode',
	pc.DESCRIPTION as name,
	'' as shortDescription,
	'<p>Pøedplatné lze objednat telefonicky na èísle +420 272 114 760 nebo emailem na adrese <a href="mailto:predplatne@czpress.cz">predplatne@czpress.cz</a></p>' as 'description:cs',
	'<p>Subscriptions can be ordered by phone at +420 272 114 760 or by email at <a href="mailto:predplatne@czpress.cz">predplatne@czpress.cz</a></p>' as 'description:en',
	'product' as itemType,
	dd.PRODUCTCODE as 'plu',
	'Èasopisy > ' as defaultCategory,
	'Èasopisy > ' as categoryText,
	replace(sysadm.sf_ScsGetCopyPrice(dd.PRODUCTCODE, 'ALAP', 'CZ', 'CZK', dd.PUBLICATIONDATE), '.', ',') 'price',
	10 as 'percentVat',
	'' as 'filteringProperty:Žánr',
	'' as 'filteringProperty:Periodicita',
	'ks' as 'unit',
	'Katalog. Èíslo;' + dd.PRODUCTCODE as 'te;tProperty',
	'0' as 'adult', -- 0 není porno èasopis
	pc.DESCRIPTION as seoTitle,
	'Vyprodáno' as 'availabilityOutOfStock',
	'Skladem' as 'availabilityInStock',
	'freeShipping' =
	CASE
		WHEN sysadm.sf_ScsGetCopyPrice(dd.PRODUCTCODE, 'ALAP', 'CZ', 'CZK', dd.PUBLICATIONDATE) > 1000 THEN '1'
		ELSE '0'
	END,
	MAX(SQ.QUANTITY) as 'stock',
	0 as 'ilustracni-fotografieFlagActive', -- 0 - ilustraèní obrázek je správný,
	'ean' =
	CASE
		WHEN patindex('% %',iss.BARCODENUMBEROUT) = 0 THEN iss.BARCODENUMBEROUT
		ELSE LEFT(iss.BARCODENUMBEROUT,patindex('% %',iss.BARCODENUMBEROUT)-1)
	END,
	cal.BOOKNUMBER, dd.DUEDATETIME
FROM (SELECT PRODUCTCODE, PUBLICATIONDATE, DUEDATETIME
		FROM HUP_DUEDATE 
		WHERE DUEDATECODE = 'ONSALE' and COMPANYCLIENTNO = 3 and DUEDATETIME = @date) dd
join HUPX_PRODUCTCODE pc on dd.PRODUCTCODE = pc.PRODUCTCODE
join DIS_PUBLICATIONCALENDAR cal 	on cal.PRODUCTCODE = dd.PRODUCTCODE and cal.PUBLICATIONDATE = dd.PUBLICATIONDATE and cal.DELIVERYPARTNERNO = 0
join CCS_ISSUE iss 	on iss.PRODUCTCODE = dd.PRODUCTCODE and iss.PUBLICATIONDATE = dd.PUBLICATIONDATE
join CCS_SHIPMENTPOS shp 	on shp.ISSUERECNO = iss.RECNO
join CCS_SHIPMENT sh 	on sh.RECNO = shp.SHIPMENTRECNO and sh.RECEIVINGPLACECLIENTNO = 1041
join STM_STOCKPRODUCT as SP	on sp.PRODUCTID = dd.PRODUCTCODE + '/FK/' + convert(varchar, dd.PUBLICATIONDATE, 23)
join STM_STOCKQUANTITY sq	on SP.PRODUCTNO = SQ.PRODUCTNO
full outer join ASA_WEBPRODUCTNAMES wn on dd.PRODUCTCODE = wn.PRODUCTCODE

WHERE dd.PRODUCTCODE NOT IN (10100, 10101, 11602, 10107, 777, 10103, 778, 23, 24, 47, 9143, 10695, 10128) and pc.PRODUCTCODE NOT IN (select wn.PRODUCTCODE from ASA_WEBPRODUCTNAMES wn)
GROUP BY dd.PRODUCTCODE, pc.DESCRIPTION, cal.BOOKNUMBER, dd.PUBLICATIONDATE, dd.DUEDATETIME, iss.BARCODENUMBEROUT 
ORDER BY pc.DESCRIPTION

SELECT  dd.PRODUCTCODE as 'kód',
		'magazin-'+WN.PRODUCTNAME+'-' as nazev,
		'jazyk' =
			CASE
				WHEN HEV.VALUE = 'USA' THEN 'US'
				WHEN HEV.VALUE = 'D' THEN 'DE'
				WHEN HEV.VALUE = 'F' THEN 'FR'
				WHEN HEV.VALUE = 'E' THEN 'ES'
				WHEN HEV.VALUE = 'S' THEN 'ES'
				WHEN HEV.VALUE = 'I' THEN 'IT'
				ELSE HEV.VALUE
			END,
		'-' + convert(varchar, cal.booknumber) as 'èíslo vydání'
FROM
	(SELECT PRODUCTCODE, PUBLICATIONDATE 
		FROM HUP_DUEDATE 
		WHERE DUEDATECODE = 'ONSALE' and COMPANYCLIENTNO = 3 and DUEDATETIME = @date) dd
	join ASA_WEBPRODUCTNAMES wn 
		ON wn.PRODUCTCODE = dd.PRODUCTCODE
	join DIS_PUBLICATIONCALENDAR cal 
		ON cal.PRODUCTCODE = dd.PRODUCTCODE and cal.PUBLICATIONDATE = dd.PUBLICATIONDATE and cal.DELIVERYPARTNERNO = 0
	left join HUPX_EXTENDEDVALUE HEV
		ON dd.PRODUCTCODE = HEV.REFERENCEID
WHERE dd.PRODUCTCODE NOT IN (10100, 10101, 11602, 10107, 777, 10103, 778, 23, 24, 47, 9143, 10695, 10128) and HEV.ITEMKEY = '5004'
ORDER BY wn.PRODUCTNAME

while @@TRANCOUNT > 0
rollback;