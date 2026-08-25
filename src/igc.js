function haversineKm(first, second) {
  const radians = (value) => value * Math.PI / 180;
  const dLat = radians(second.lat - first.lat);
  const dLon = radians(second.lon - first.lon);
  const lat1 = radians(first.lat);
  const lat2 = radians(second.lat);
  const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) ** 2;
  return 6371.0088 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function parseIgc(content) {
  const normalized = String(content || '').replace(/\r/g, '');
  if (!normalized || Buffer.byteLength(normalized, 'utf8') > 2_000_000) {
    throw Object.assign(new Error('O ficheiro IGC está vazio ou excede 2 MB.'), { status: 422 });
  }
  const lines = normalized.split('\n').map((line) => line.trim()).filter(Boolean);
  const dateLine = lines.find((line) => /^HFDTE\d{6}/.test(line));
  if (!dateLine) throw Object.assign(new Error('O IGC não contém uma data HFDTE válida.'), { status: 422 });
  const day = Number(dateLine.slice(5, 7));
  const month = Number(dateLine.slice(7, 9));
  const shortYear = Number(dateLine.slice(9, 11));
  const year = shortYear >= 70 ? 1900 + shortYear : 2000 + shortYear;
  const baseDate = Date.UTC(year, month - 1, day);
  const fixes = [];
  let dayOffset = 0;
  let previousSeconds = null;
  for (const line of lines) {
    if (!/^B\d{6}\d{7}[NS]\d{8}[EW][AV]/.test(line) || line.length < 35) continue;
    const hour = Number(line.slice(1, 3));
    const minute = Number(line.slice(3, 5));
    const second = Number(line.slice(5, 7));
    const seconds = hour * 3600 + minute * 60 + second;
    if (previousSeconds !== null && seconds + 43200 < previousSeconds) dayOffset += 86400;
    previousSeconds = seconds;
    const lat = Number(line.slice(7, 9)) + Number(line.slice(9, 14)) / 60000;
    const lon = Number(line.slice(15, 18)) + Number(line.slice(18, 23)) / 60000;
    const altitude = Number(line.slice(30, 35));
    if (![lat, lon, altitude].every(Number.isFinite)) continue;
    fixes.push({ timestamp: new Date(baseDate + (dayOffset + seconds) * 1000), lat: line[14] === 'S' ? -lat : lat, lon: line[23] === 'W' ? -lon : lon, altitude });
  }
  if (fixes.length < 2) throw Object.assign(new Error('O IGC não contém pontos de voo suficientes.'), { status: 422 });
  let distanceKm = 0;
  let maxSpeedKmh = 0;
  for (let index = 1; index < fixes.length; index += 1) {
    const segmentKm = haversineKm(fixes[index - 1], fixes[index]);
    const seconds = (fixes[index].timestamp - fixes[index - 1].timestamp) / 1000;
    distanceKm += segmentKm;
    if (seconds > 0 && seconds <= 120) maxSpeedKmh = Math.max(maxSpeedKmh, segmentKm / seconds * 3600);
  }
  const durationSeconds = Math.max(0, Math.round((fixes.at(-1).timestamp - fixes[0].timestamp) / 1000));
  const sampleStep = Math.max(1, Math.ceil(fixes.length / 600));
  const trackPoints = fixes.filter((_, index) => index % sampleStep === 0 || index === fixes.length - 1).map((fix) => [Number(fix.lat.toFixed(6)), Number(fix.lon.toFixed(6)), fix.altitude]);
  return {
    flownAt: fixes[0].timestamp,
    durationSeconds,
    distanceKm: Number(distanceKm.toFixed(2)),
    maxAltitudeM: Math.max(...fixes.map((fix) => fix.altitude)),
    averageSpeedKmh: durationSeconds ? Number((distanceKm / durationSeconds * 3600).toFixed(2)) : 0,
    maxSpeedKmh: Number(maxSpeedKmh.toFixed(2)),
    takeoff: fixes[0],
    landing: fixes.at(-1),
    trackPoints,
    signaturePresent: lines.some((line) => line.startsWith('G')),
    normalized,
  };
}
