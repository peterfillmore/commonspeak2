CREATE TEMPORARY FUNCTION parseRoutes(routesCode STRING)
RETURNS ARRAY<STRING> LANGUAGE js AS """
  result = [];
  var regexFullMatch = /\\.get\\(('|")\\/([a-zA-Z_0-9\\/\\:!@$%^&*()+=]*)('|")/mgi;
  var regexPartial = /('|")(.*)('|")/i;
  if(regexFullMatch.test(routesCode)) {
       var fullmatch = routesCode.match(regexFullMatch);
       for (var i in fullmatch) {
            if(regexPartial.test(fullmatch[i])) {
                 result.push(fullmatch[i].match(regexPartial)[2]);
            };
       };
  };
  return result;
  """;

SELECT
  route,
  COUNT(route) AS count
FROM (
  SELECT
    parseRoutes(c.content) AS route
  FROM
    `bigquery-public-data.github_repos.contents` c
  JOIN (
    SELECT
      id
    FROM
      `bigquery-public-data.github_repos.files`
    WHERE
      path LIKE '%.js') f
  ON
    f.id = c.id ) routes,
    UNNEST(route) AS route
WHERE
  route IS NOT NULL
GROUP BY
  route
ORDER BY
  count DESC
LIMIT
  {{limit}}
