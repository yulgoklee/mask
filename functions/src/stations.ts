/**
 * 전국 에어코리아 대기 측정소 목록 (번들 데이터)
 *
 * 출처: 한국환경공단 에어코리아 측정소 정보
 * MsrstnInfoInqireSvc API 키가 없어도 측정소 검색이 가능하도록
 * 주요 측정소 목록을 번들로 내장합니다.
 */

export interface Station {
  stationName: string;
  sidoName: string;
  addr: string;
}

export const STATIONS: Station[] = [
  // ── 서울 ──────────────────────────────────────────────
  { stationName: "강남구", sidoName: "서울", addr: "서울 강남구" },
  { stationName: "강동구", sidoName: "서울", addr: "서울 강동구" },
  { stationName: "강북구", sidoName: "서울", addr: "서울 강북구" },
  { stationName: "강서구", sidoName: "서울", addr: "서울 강서구" },
  { stationName: "관악구", sidoName: "서울", addr: "서울 관악구" },
  { stationName: "광진구", sidoName: "서울", addr: "서울 광진구" },
  { stationName: "구로구", sidoName: "서울", addr: "서울 구로구" },
  { stationName: "금천구", sidoName: "서울", addr: "서울 금천구" },
  { stationName: "노원구", sidoName: "서울", addr: "서울 노원구" },
  { stationName: "도봉구", sidoName: "서울", addr: "서울 도봉구" },
  { stationName: "동대문구", sidoName: "서울", addr: "서울 동대문구" },
  { stationName: "동작구", sidoName: "서울", addr: "서울 동작구" },
  { stationName: "마포구", sidoName: "서울", addr: "서울 마포구" },
  { stationName: "서대문구", sidoName: "서울", addr: "서울 서대문구" },
  { stationName: "서초구", sidoName: "서울", addr: "서울 서초구" },
  { stationName: "성동구", sidoName: "서울", addr: "서울 성동구" },
  { stationName: "성북구", sidoName: "서울", addr: "서울 성북구" },
  { stationName: "송파구", sidoName: "서울", addr: "서울 송파구" },
  { stationName: "양천구", sidoName: "서울", addr: "서울 양천구" },
  { stationName: "영등포구", sidoName: "서울", addr: "서울 영등포구" },
  { stationName: "용산구", sidoName: "서울", addr: "서울 용산구" },
  { stationName: "은평구", sidoName: "서울", addr: "서울 은평구" },
  { stationName: "종로구", sidoName: "서울", addr: "서울 종로구" },
  { stationName: "중구", sidoName: "서울", addr: "서울 중구" },
  { stationName: "중랑구", sidoName: "서울", addr: "서울 중랑구" },

  // ── 경기 ──────────────────────────────────────────────
  { stationName: "인계동", sidoName: "경기", addr: "경기 수원시 팔달구 인계동" },
  { stationName: "수내동", sidoName: "경기", addr: "경기 성남시 분당구 수내동" },
  { stationName: "행신동", sidoName: "경기", addr: "경기 고양시 덕양구 행신동" },
  { stationName: "수지", sidoName: "경기", addr: "경기 용인시 수지구" },
  { stationName: "중2동", sidoName: "경기", addr: "경기 부천시 중2동" },
  { stationName: "고잔동", sidoName: "경기", addr: "경기 안산시 단원구 고잔동" },
  { stationName: "안양8동", sidoName: "경기", addr: "경기 안양시 만안구 안양8동" },
  { stationName: "금곡동", sidoName: "경기", addr: "경기 남양주시 금곡동" },
  { stationName: "동탄", sidoName: "경기", addr: "경기 화성시 동탄" },
  { stationName: "비전동", sidoName: "경기", addr: "경기 평택시 비전동" },
  { stationName: "의정부동", sidoName: "경기", addr: "경기 의정부시 의정부동" },
  { stationName: "운정", sidoName: "경기", addr: "경기 파주시 운정동" },
  { stationName: "경안동", sidoName: "경기", addr: "경기 광주시 경안동" },
  { stationName: "사우동", sidoName: "경기", addr: "경기 김포시 사우동" },
  { stationName: "정왕동", sidoName: "경기", addr: "경기 시흥시 정왕동" },
  { stationName: "미사", sidoName: "경기", addr: "경기 하남시 미사동" },
  { stationName: "이의동", sidoName: "경기", addr: "경기 수원시 영통구 이의동" },
  { stationName: "처인구", sidoName: "경기", addr: "경기 용인시 처인구" },
  { stationName: "중원구", sidoName: "경기", addr: "경기 성남시 중원구" },
  { stationName: "덕양구", sidoName: "경기", addr: "경기 고양시 덕양구" },
  { stationName: "오산", sidoName: "경기", addr: "경기 오산시" },
  { stationName: "구리", sidoName: "경기", addr: "경기 구리시" },
  { stationName: "광명", sidoName: "경기", addr: "경기 광명시" },
  { stationName: "군포", sidoName: "경기", addr: "경기 군포시" },
  { stationName: "의왕", sidoName: "경기", addr: "경기 의왕시" },
  { stationName: "이천", sidoName: "경기", addr: "경기 이천시" },
  { stationName: "양주", sidoName: "경기", addr: "경기 양주시" },
  { stationName: "포천", sidoName: "경기", addr: "경기 포천시" },
  { stationName: "여주", sidoName: "경기", addr: "경기 여주시" },
  { stationName: "양평", sidoName: "경기", addr: "경기 양평군" },
  { stationName: "가평", sidoName: "경기", addr: "경기 가평군" },
  { stationName: "동두천", sidoName: "경기", addr: "경기 동두천시" },
  { stationName: "과천", sidoName: "경기", addr: "경기 과천시" },
  { stationName: "안성", sidoName: "경기", addr: "경기 안성시" },
  { stationName: "연천", sidoName: "경기", addr: "경기 연천군" },

  // ── 인천 ──────────────────────────────────────────────
  { stationName: "구월동", sidoName: "인천", addr: "인천 남동구 구월동" },
  { stationName: "동춘", sidoName: "인천", addr: "인천 연수구 동춘동" },
  { stationName: "부평", sidoName: "인천", addr: "인천 부평구 부평동" },
  { stationName: "계산", sidoName: "인천", addr: "인천 계양구 계산동" },
  { stationName: "청라", sidoName: "인천", addr: "인천 서구 청라동" },
  { stationName: "송도", sidoName: "인천", addr: "인천 연수구 송도동" },
  { stationName: "항동", sidoName: "인천", addr: "인천 중구 항동" },
  { stationName: "검단", sidoName: "인천", addr: "인천 서구 검단동" },
  { stationName: "강화", sidoName: "인천", addr: "인천 강화군" },

  // ── 부산 ──────────────────────────────────────────────
  { stationName: "광복동", sidoName: "부산", addr: "부산 중구 광복동" },
  { stationName: "온천동", sidoName: "부산", addr: "부산 동래구 온천동" },
  { stationName: "감천동", sidoName: "부산", addr: "부산 사하구 감천동" },
  { stationName: "화명동", sidoName: "부산", addr: "부산 북구 화명동" },
  { stationName: "우동", sidoName: "부산", addr: "부산 해운대구 우동" },
  { stationName: "학장동", sidoName: "부산", addr: "부산 사상구 학장동" },
  { stationName: "연산동", sidoName: "부산", addr: "부산 연제구 연산동" },
  { stationName: "대연동", sidoName: "부산", addr: "부산 남구 대연동" },
  { stationName: "전포동", sidoName: "부산", addr: "부산 부산진구 전포동" },
  { stationName: "장림동", sidoName: "부산", addr: "부산 사하구 장림동" },
  { stationName: "기장읍", sidoName: "부산", addr: "부산 기장군 기장읍" },

  // ── 대구 ──────────────────────────────────────────────
  { stationName: "수창동", sidoName: "대구", addr: "대구 중구 수창동" },
  { stationName: "이곡동", sidoName: "대구", addr: "대구 달서구 이곡동" },
  { stationName: "만촌동", sidoName: "대구", addr: "대구 수성구 만촌동" },
  { stationName: "검사동", sidoName: "대구", addr: "대구 동구 검사동" },
  { stationName: "칠성동", sidoName: "대구", addr: "대구 북구 칠성동" },
  { stationName: "비산동", sidoName: "대구", addr: "대구 서구 비산동" },
  { stationName: "대명동", sidoName: "대구", addr: "대구 남구 대명동" },
  { stationName: "다사읍", sidoName: "대구", addr: "대구 달성군 다사읍" },

  // ── 광주 ──────────────────────────────────────────────
  { stationName: "서석동", sidoName: "광주", addr: "광주 동구 서석동" },
  { stationName: "치평동", sidoName: "광주", addr: "광주 서구 치평동" },
  { stationName: "두암동", sidoName: "광주", addr: "광주 북구 두암동" },
  { stationName: "일곡동", sidoName: "광주", addr: "광주 북구 일곡동" },
  { stationName: "주월동", sidoName: "광주", addr: "광주 남구 주월동" },
  { stationName: "노대동", sidoName: "광주", addr: "광주 남구 노대동" },
  { stationName: "평동", sidoName: "광주", addr: "광주 광산구 평동" },
  { stationName: "월곡동", sidoName: "광주", addr: "광주 광산구 월곡동" },
  { stationName: "내방동", sidoName: "광주", addr: "광주 서구 내방동" },

  // ── 대전 ──────────────────────────────────────────────
  { stationName: "둔산동", sidoName: "대전", addr: "대전 서구 둔산동" },
  { stationName: "노은동", sidoName: "대전", addr: "대전 유성구 노은동" },
  { stationName: "문창동", sidoName: "대전", addr: "대전 중구 문창동" },
  { stationName: "대성동", sidoName: "대전", addr: "대전 유성구 대성동" },
  { stationName: "읍내동", sidoName: "대전", addr: "대전 대덕구 읍내동" },
  { stationName: "비래동", sidoName: "대전", addr: "대전 동구 비래동" },
  { stationName: "판암동", sidoName: "대전", addr: "대전 동구 판암동" },

  // ── 울산 ──────────────────────────────────────────────
  { stationName: "무거동", sidoName: "울산", addr: "울산 남구 무거동" },
  { stationName: "삼산동", sidoName: "울산", addr: "울산 남구 삼산동" },
  { stationName: "신정동", sidoName: "울산", addr: "울산 남구 신정동" },
  { stationName: "농소동", sidoName: "울산", addr: "울산 북구 농소동" },
  { stationName: "삼남읍", sidoName: "울산", addr: "울산 울주군 삼남읍" },
  { stationName: "언양읍", sidoName: "울산", addr: "울산 울주군 언양읍" },
  { stationName: "성남동", sidoName: "울산", addr: "울산 중구 성남동" },
  { stationName: "전하동", sidoName: "울산", addr: "울산 동구 전하동" },

  // ── 세종 ──────────────────────────────────────────────
  { stationName: "한솔동", sidoName: "세종", addr: "세종 한솔동" },
  { stationName: "아름동", sidoName: "세종", addr: "세종 아름동" },
  { stationName: "조치원읍", sidoName: "세종", addr: "세종 조치원읍" },
  { stationName: "소담동", sidoName: "세종", addr: "세종 소담동" },
  { stationName: "고운동", sidoName: "세종", addr: "세종 고운동" },
  { stationName: "도담동", sidoName: "세종", addr: "세종 도담동" },

  // ── 강원 ──────────────────────────────────────────────
  { stationName: "약사동", sidoName: "강원", addr: "강원 춘천시 약사동" },
  { stationName: "단계동", sidoName: "강원", addr: "강원 원주시 단계동" },
  { stationName: "옥천동", sidoName: "강원", addr: "강원 강릉시 옥천동" },
  { stationName: "조양동", sidoName: "강원", addr: "강원 속초시 조양동" },
  { stationName: "천곡동", sidoName: "강원", addr: "강원 동해시 천곡동" },
  { stationName: "남양동", sidoName: "강원", addr: "강원 삼척시 남양동" },
  { stationName: "황지동", sidoName: "강원", addr: "강원 태백시 황지동" },
  { stationName: "영월읍", sidoName: "강원", addr: "강원 영월군 영월읍" },
  { stationName: "정선읍", sidoName: "강원", addr: "강원 정선군 정선읍" },
  { stationName: "홍천읍", sidoName: "강원", addr: "강원 홍천군 홍천읍" },
  { stationName: "원주", sidoName: "강원", addr: "강원 원주시" },
  { stationName: "춘천", sidoName: "강원", addr: "강원 춘천시" },
  { stationName: "강릉", sidoName: "강원", addr: "강원 강릉시" },
  { stationName: "속초", sidoName: "강원", addr: "강원 속초시" },
  { stationName: "철원", sidoName: "강원", addr: "강원 철원군" },
  { stationName: "양양", sidoName: "강원", addr: "강원 양양군" },
  { stationName: "고성", sidoName: "강원", addr: "강원 고성군" },

  // ── 충북 ──────────────────────────────────────────────
  { stationName: "상당구", sidoName: "충북", addr: "충북 청주시 상당구" },
  { stationName: "흥덕구", sidoName: "충북", addr: "충북 청주시 흥덕구" },
  { stationName: "서원구", sidoName: "충북", addr: "충북 청주시 서원구" },
  { stationName: "청원구", sidoName: "충북", addr: "충북 청주시 청원구" },
  { stationName: "교현동", sidoName: "충북", addr: "충북 충주시 교현동" },
  { stationName: "의림동", sidoName: "충북", addr: "충북 제천시 의림동" },
  { stationName: "청주", sidoName: "충북", addr: "충북 청주시" },
  { stationName: "충주", sidoName: "충북", addr: "충북 충주시" },
  { stationName: "제천", sidoName: "충북", addr: "충북 제천시" },
  { stationName: "보은", sidoName: "충북", addr: "충북 보은군" },
  { stationName: "옥천", sidoName: "충북", addr: "충북 옥천군" },
  { stationName: "영동", sidoName: "충북", addr: "충북 영동군" },
  { stationName: "진천", sidoName: "충북", addr: "충북 진천군" },
  { stationName: "음성", sidoName: "충북", addr: "충북 음성군" },
  { stationName: "단양", sidoName: "충북", addr: "충북 단양군" },
  { stationName: "증평", sidoName: "충북", addr: "충북 증평군" },

  // ── 충남 ──────────────────────────────────────────────
  { stationName: "신방동", sidoName: "충남", addr: "충남 천안시 동남구 신방동" },
  { stationName: "불당동", sidoName: "충남", addr: "충남 천안시 서북구 불당동" },
  { stationName: "신관동", sidoName: "충남", addr: "충남 공주시 신관동" },
  { stationName: "대천동", sidoName: "충남", addr: "충남 보령시 대천동" },
  { stationName: "모종동", sidoName: "충남", addr: "충남 아산시 모종동" },
  { stationName: "동문동", sidoName: "충남", addr: "충남 서산시 동문동" },
  { stationName: "취암동", sidoName: "충남", addr: "충남 논산시 취암동" },
  { stationName: "당진읍", sidoName: "충남", addr: "충남 당진시 당진읍" },
  { stationName: "홍성읍", sidoName: "충남", addr: "충남 홍성군 홍성읍" },
  { stationName: "천안", sidoName: "충남", addr: "충남 천안시" },
  { stationName: "공주", sidoName: "충남", addr: "충남 공주시" },
  { stationName: "서산", sidoName: "충남", addr: "충남 서산시" },
  { stationName: "아산", sidoName: "충남", addr: "충남 아산시" },
  { stationName: "논산", sidoName: "충남", addr: "충남 논산시" },
  { stationName: "당진", sidoName: "충남", addr: "충남 당진시" },
  { stationName: "태안", sidoName: "충남", addr: "충남 태안군" },
  { stationName: "부여", sidoName: "충남", addr: "충남 부여군" },
  { stationName: "서천", sidoName: "충남", addr: "충남 서천군" },
  { stationName: "금산", sidoName: "충남", addr: "충남 금산군" },

  // ── 전북 ──────────────────────────────────────────────
  { stationName: "효자동", sidoName: "전북", addr: "전북 전주시 완산구 효자동" },
  { stationName: "완산구", sidoName: "전북", addr: "전북 전주시 완산구" },
  { stationName: "덕진구", sidoName: "전북", addr: "전북 전주시 덕진구" },
  { stationName: "조촌동", sidoName: "전북", addr: "전북 군산시 조촌동" },
  { stationName: "영등동", sidoName: "전북", addr: "전북 익산시 영등동" },
  { stationName: "상동", sidoName: "전북", addr: "전북 정읍시 상동" },
  { stationName: "왕정동", sidoName: "전북", addr: "전북 남원시 왕정동" },
  { stationName: "전주", sidoName: "전북", addr: "전북 전주시" },
  { stationName: "군산", sidoName: "전북", addr: "전북 군산시" },
  { stationName: "익산", sidoName: "전북", addr: "전북 익산시" },
  { stationName: "정읍", sidoName: "전북", addr: "전북 정읍시" },
  { stationName: "남원", sidoName: "전북", addr: "전북 남원시" },
  { stationName: "김제", sidoName: "전북", addr: "전북 김제시" },
  { stationName: "완주", sidoName: "전북", addr: "전북 완주군" },
  { stationName: "진안", sidoName: "전북", addr: "전북 진안군" },
  { stationName: "무주", sidoName: "전북", addr: "전북 무주군" },
  { stationName: "고창", sidoName: "전북", addr: "전북 고창군" },
  { stationName: "부안", sidoName: "전북", addr: "전북 부안군" },

  // ── 전남 ──────────────────────────────────────────────
  { stationName: "산정동", sidoName: "전남", addr: "전남 목포시 산정동" },
  { stationName: "돌산읍", sidoName: "전남", addr: "전남 여수시 돌산읍" },
  { stationName: "문수동", sidoName: "전남", addr: "전남 여수시 문수동" },
  { stationName: "조례동", sidoName: "전남", addr: "전남 순천시 조례동" },
  { stationName: "덕암동", sidoName: "전남", addr: "전남 순천시 덕암동" },
  { stationName: "송월동", sidoName: "전남", addr: "전남 나주시 송월동" },
  { stationName: "광양읍", sidoName: "전남", addr: "전남 광양시 광양읍" },
  { stationName: "목포", sidoName: "전남", addr: "전남 목포시" },
  { stationName: "여수", sidoName: "전남", addr: "전남 여수시" },
  { stationName: "순천", sidoName: "전남", addr: "전남 순천시" },
  { stationName: "나주", sidoName: "전남", addr: "전남 나주시" },
  { stationName: "광양", sidoName: "전남", addr: "전남 광양시" },
  { stationName: "담양", sidoName: "전남", addr: "전남 담양군" },
  { stationName: "곡성", sidoName: "전남", addr: "전남 곡성군" },
  { stationName: "고흥", sidoName: "전남", addr: "전남 고흥군" },
  { stationName: "화순", sidoName: "전남", addr: "전남 화순군" },
  { stationName: "장흥", sidoName: "전남", addr: "전남 장흥군" },
  { stationName: "강진", sidoName: "전남", addr: "전남 강진군" },
  { stationName: "해남", sidoName: "전남", addr: "전남 해남군" },
  { stationName: "영암", sidoName: "전남", addr: "전남 영암군" },
  { stationName: "무안", sidoName: "전남", addr: "전남 무안군" },
  { stationName: "영광", sidoName: "전남", addr: "전남 영광군" },
  { stationName: "완도", sidoName: "전남", addr: "전남 완도군" },
  { stationName: "진도", sidoName: "전남", addr: "전남 진도군" },

  // ── 경북 ──────────────────────────────────────────────
  { stationName: "대잠동", sidoName: "경북", addr: "경북 포항시 남구 대잠동" },
  { stationName: "해도동", sidoName: "경북", addr: "경북 포항시 북구 해도동" },
  { stationName: "황성동", sidoName: "경북", addr: "경북 경주시 황성동" },
  { stationName: "응명동", sidoName: "경북", addr: "경북 김천시 응명동" },
  { stationName: "옥야동", sidoName: "경북", addr: "경북 안동시 옥야동" },
  { stationName: "원평동", sidoName: "경북", addr: "경북 구미시 원평동" },
  { stationName: "영주동", sidoName: "경북", addr: "경북 영주시 영주동" },
  { stationName: "야사동", sidoName: "경북", addr: "경북 영천시 야사동" },
  { stationName: "무양동", sidoName: "경북", addr: "경북 상주시 무양동" },
  { stationName: "중방동", sidoName: "경북", addr: "경북 경산시 중방동" },
  { stationName: "포항", sidoName: "경북", addr: "경북 포항시" },
  { stationName: "경주", sidoName: "경북", addr: "경북 경주시" },
  { stationName: "김천", sidoName: "경북", addr: "경북 김천시" },
  { stationName: "안동", sidoName: "경북", addr: "경북 안동시" },
  { stationName: "구미", sidoName: "경북", addr: "경북 구미시" },
  { stationName: "영주", sidoName: "경북", addr: "경북 영주시" },
  { stationName: "영천", sidoName: "경북", addr: "경북 영천시" },
  { stationName: "상주", sidoName: "경북", addr: "경북 상주시" },
  { stationName: "경산", sidoName: "경북", addr: "경북 경산시" },
  { stationName: "칠곡", sidoName: "경북", addr: "경북 칠곡군" },
  { stationName: "예천", sidoName: "경북", addr: "경북 예천군" },
  { stationName: "봉화", sidoName: "경북", addr: "경북 봉화군" },
  { stationName: "울진", sidoName: "경북", addr: "경북 울진군" },
  { stationName: "의성", sidoName: "경북", addr: "경북 의성군" },
  { stationName: "청송", sidoName: "경북", addr: "경북 청송군" },
  { stationName: "영양", sidoName: "경북", addr: "경북 영양군" },
  { stationName: "영덕", sidoName: "경북", addr: "경북 영덕군" },
  { stationName: "청도", sidoName: "경북", addr: "경북 청도군" },
  { stationName: "고령", sidoName: "경북", addr: "경북 고령군" },
  { stationName: "성주", sidoName: "경북", addr: "경북 성주군" },

  // ── 경남 ──────────────────────────────────────────────
  { stationName: "의창구", sidoName: "경남", addr: "경남 창원시 의창구" },
  { stationName: "성산구", sidoName: "경남", addr: "경남 창원시 성산구" },
  { stationName: "회원구", sidoName: "경남", addr: "경남 창원시 마산회원구" },
  { stationName: "진해구", sidoName: "경남", addr: "경남 창원시 진해구" },
  { stationName: "망경동", sidoName: "경남", addr: "경남 진주시 망경동" },
  { stationName: "무전동", sidoName: "경남", addr: "경남 통영시 무전동" },
  { stationName: "내동", sidoName: "경남", addr: "경남 김해시 내동" },
  { stationName: "내이동", sidoName: "경남", addr: "경남 밀양시 내이동" },
  { stationName: "고현동", sidoName: "경남", addr: "경남 거제시 고현동" },
  { stationName: "북부동", sidoName: "경남", addr: "경남 양산시 북부동" },
  { stationName: "창원", sidoName: "경남", addr: "경남 창원시" },
  { stationName: "진주", sidoName: "경남", addr: "경남 진주시" },
  { stationName: "통영", sidoName: "경남", addr: "경남 통영시" },
  { stationName: "김해", sidoName: "경남", addr: "경남 김해시" },
  { stationName: "밀양", sidoName: "경남", addr: "경남 밀양시" },
  { stationName: "거제", sidoName: "경남", addr: "경남 거제시" },
  { stationName: "양산", sidoName: "경남", addr: "경남 양산시" },
  { stationName: "사천", sidoName: "경남", addr: "경남 사천시" },
  { stationName: "의령", sidoName: "경남", addr: "경남 의령군" },
  { stationName: "함안", sidoName: "경남", addr: "경남 함안군" },
  { stationName: "창녕", sidoName: "경남", addr: "경남 창녕군" },
  { stationName: "남해", sidoName: "경남", addr: "경남 남해군" },
  { stationName: "하동", sidoName: "경남", addr: "경남 하동군" },
  { stationName: "산청", sidoName: "경남", addr: "경남 산청군" },
  { stationName: "함양", sidoName: "경남", addr: "경남 함양군" },
  { stationName: "거창", sidoName: "경남", addr: "경남 거창군" },
  { stationName: "합천", sidoName: "경남", addr: "경남 합천군" },

  // ── 제주 ──────────────────────────────────────────────
  { stationName: "이도동", sidoName: "제주", addr: "제주 제주시 이도동" },
  { stationName: "연동", sidoName: "제주", addr: "제주 제주시 연동" },
  { stationName: "도두동", sidoName: "제주", addr: "제주 제주시 도두동" },
  { stationName: "서귀동", sidoName: "제주", addr: "제주 서귀포시 서귀동" },
  { stationName: "성산읍", sidoName: "제주", addr: "제주 서귀포시 성산읍" },
  { stationName: "대정읍", sidoName: "제주", addr: "제주 서귀포시 대정읍" },
  { stationName: "제주", sidoName: "제주", addr: "제주 제주시" },
  { stationName: "서귀포", sidoName: "제주", addr: "제주 서귀포시" },
];

/**
 * 키워드로 측정소 검색 (stationName, addr 에서 부분 일치)
 */
export function searchStations(keyword: string, limit = 20): Station[] {
  const q = keyword.trim().toLowerCase();
  if (!q) return [];
  return STATIONS.filter(
    (s) =>
      s.stationName.toLowerCase().includes(q) ||
      s.addr.toLowerCase().includes(q)
  ).slice(0, limit);
}

/**
 * 측정소명으로 시도명 조회
 */
export function getSidoByStation(stationName: string): string | null {
  return STATIONS.find((s) => s.stationName === stationName)?.sidoName ?? null;
}
