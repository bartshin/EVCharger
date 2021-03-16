## 전기차 충전소 검색이 가능한 어플 (ios, swift)

### EV_API
공공데이터 api의 데이터를 mysql db로 옮기기 위한 툴

- 옮기기전 데이터
```xml
<item>
<statNm>종묘 공영주차장</statNm>
<statId>ME000001</statId>
<chgerId>01</chgerId>
<chgerType>03</chgerType>
<addr>서울특별시 종로구 종로 157, 지하주차장 4층 하층 T구역</addr>
<lat>37.571076</lat>
<lng>126.995880</lng>
<useTime>24시간 이용가능</useTime>
<busiId>ME</busiId>
<busiNm>환경부</busiNm>
<busiCall>1661-9408</busiCall>
<stat>5</stat>
<statUpdDt>20210316132832</statUpdDt>
<powerType>급속(50kW)</powerType>
<zcode>11</zcode>
<parkingFree>Y</parkingFree>
<note/>
</item>
```

- 옮긴 후 데이터
``` mysql
| stationId | stationName            | chargerId | chargerType | address                                                                   | latitude  | longitude  | timeAvailable       | organId | organName | organCallNumber | powerType    | note | zcode |
+-----------+------------------------+-----------+-------------+---------------------------------------------------------------------------+-----------+------------+---------------------+---------+-----------+-----------------+--------------+------+-------+
| ME000001  | 종묘 공영주차장        | 01        | 03          | 서울특별시 종로구 종로 157, 지하주차장 4층 하층 T구역                     | 37.571075 | 126.995880 | 시간 이용가능       | ME      | 환경부    | 1661-9408       | 급속(50kW)   |      |    11 |

```

### EV_Query
AWS Lambda, AWS api gateway를 이용해 http요청을 받아 db의 데이터를 검색할수 있는 함수

좌표를
