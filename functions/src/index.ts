import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { setGlobalOptions } from "firebase-functions/v2";

// 서울 리전 — 한국 유저 레이턴시 최소화
setGlobalOptions({ region: "asia-northeast3", maxInstances: 10 });

// 에어코리아 API 키 — Firebase Secret Manager에 저장
// 설정 방법: firebase functions:secrets:set AIRKOREA_API_KEY
const airKoreaApiKey = defineSecret("AIRKOREA_API_KEY");

const AIR_KOREA_ARPLTN =
  "https://apis.data.go.kr/B552584/ArpltnInforInqireSvc";
const AIR_KOREA_MSRSTN =
  "https://apis.data.go.kr/B552584/MsrstnInfoInqireSvc";

// ── 공통 헬퍼 ────────────────────────────────────────────

/** AirKorea API 공통 호출
 *
 * serviceKey는 이미 URL 인코딩된 값이므로 URLSearchParams를 사용하지 않고
 * URL을 직접 조립합니다. (URLSearchParams는 값을 한 번 더 인코딩함)
 */
async function callAirKorea(
  baseUrl: string,
  endpoint: string,
  params: Record<string, string>,
  apiKey: string
): Promise<unknown> {
  const extraParams = Object.entries(params)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join("&");

  const url =
    `${baseUrl}/${endpoint}` +
    `?serviceKey=${apiKey}` +
    `&returnType=json` +
    `&${extraParams}`;

  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`AirKorea HTTP error: ${res.status}`);
  }
  return res.json();
}

/** CORS + JSON 응답 헬퍼 */
function sendJson(
  res: import("express").Response,
  data: unknown,
  status = 200
): void {
  res.set("Access-Control-Allow-Origin", "*");
  res.status(status).json(data);
}

// ── Endpoint 1: 실시간 측정 데이터 프록시 ──────────────────
// 사용처: getDustData, getHourlyData, getHourlyHistory
//
// 쿼리 파라미터:
//   stationName: 측정소명 (필수)
//   numOfRows  : 행 수 (기본 1)
//   dataTerm   : DAILY | MONTH | 3MONTH (기본 DAILY)

export const proxyMeasurement = onRequest(
  { secrets: [airKoreaApiKey] },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      sendJson(res, {});
      return;
    }

    const stationName = req.query["stationName"] as string | undefined;
    if (!stationName) {
      sendJson(res, { error: "stationName required" }, 400);
      return;
    }

    try {
      const data = await callAirKorea(
        AIR_KOREA_ARPLTN,
        "getMsrstnAcctoRltmMesureDnsty",
        {
          numOfRows: (req.query["numOfRows"] as string) ?? "1",
          pageNo: "1",
          stationName: stationName,
          dataTerm: (req.query["dataTerm"] as string) ?? "DAILY",
          ver: "1.0",
        },
        airKoreaApiKey.value()
      );
      sendJson(res, data);
    } catch (e) {
      console.error("[proxyMeasurement] 오류:", e);
      sendJson(res, { error: "upstream error" }, 502);
    }
  }
);

// ── Endpoint 2: 단기 예보 데이터 프록시 ───────────────────
// 사용처: getWeeklyForecast, getTomorrowForecast
//
// 쿼리 파라미터:
//   searchDate: 조회 날짜 YYYY-MM-DD (필수)
//   informCode: PM10 | PM25 (필수)
//   numOfRows : 행 수 (기본 20)

export const proxyForecast = onRequest(
  { secrets: [airKoreaApiKey] },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      sendJson(res, {});
      return;
    }

    const searchDate = req.query["searchDate"] as string | undefined;
    const informCode = req.query["informCode"] as string | undefined;

    if (!searchDate || !informCode) {
      sendJson(res, { error: "searchDate and informCode required" }, 400);
      return;
    }

    try {
      const data = await callAirKorea(
        AIR_KOREA_ARPLTN,
        "getMinuDustFrcstDspth",
        {
          numOfRows: (req.query["numOfRows"] as string) ?? "20",
          pageNo: "1",
          searchDate: searchDate,
          informCode: informCode,
        },
        airKoreaApiKey.value()
      );
      sendJson(res, data);
    } catch (e) {
      console.error("[proxyForecast] 오류:", e);
      sendJson(res, { error: "upstream error" }, 502);
    }
  }
);

// ── Endpoint 3: 측정소 목록 프록시 ────────────────────────
// 사용처: searchStations, getSidoForStation
//
// 쿼리 파라미터:
//   stationName: 측정소명 또는 키워드 (필수)
//   numOfRows  : 행 수 (기본 20)

export const proxyStations = onRequest(
  { secrets: [airKoreaApiKey] },
  async (req, res) => {
    if (req.method === "OPTIONS") {
      sendJson(res, {});
      return;
    }

    const stationName = req.query["stationName"] as string | undefined;
    if (!stationName) {
      sendJson(res, { error: "stationName required" }, 400);
      return;
    }

    try {
      // getMsrstnList는 MsrstnInfoInqireSvc 서비스 하위 엔드포인트
      const data = await callAirKorea(
        AIR_KOREA_MSRSTN,
        "getMsrstnList",
        {
          numOfRows: (req.query["numOfRows"] as string) ?? "20",
          pageNo: "1",
          stationName: stationName,
        },
        airKoreaApiKey.value()
      );
      sendJson(res, data);
    } catch (e) {
      console.error("[proxyStations] 오류:", e);
      sendJson(res, { error: "upstream error" }, 502);
    }
  }
);
