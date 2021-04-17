const fs = require('fs')
const axios = require('axios')
const moment = require('moment')
const { exec } = require('child_process')

let now = Date.now()
let lastSettingTime = 0

setInterval(() => {
  let path = __dirname

  now = Date.now()

  let filename = `${path}/block_tps.log`

  let baseUrl = `http://localhost:9090`
  let apiPath = `/api/v1/query`
  let jobName = `hyperledger_metrics`
  let metricName = `endorser_proposals_received`
  let interval = `5s`
  let query = encodeURI(`query=sum by (job)(rate(${metricName}{job="${jobName}"}[${interval}]))`)

  axios.get(`${baseUrl}${apiPath}?${query}`).then((response) => {
    let tps = Number(response.data.data.result[0].value[1])
    fs.appendFileSync(filename, `[${moment(now).format('YYYY-MM-DD H:m:ss')}] TPS: ${tps}\n`)
    let blockSize = 0

    if ( tps > 0 && tps < 50 ) {
      blockSize = 10
    } else if ( tps >= 50 ) {
      blockSize = Math.floor(tps / 50) * 50 + 25
    }

    if ( blockSize > 0 && parseInt((parseInt(now - lastSettingTime)) / 1000) > 1 ) {
      let command = `./changeChannelConfig.sh 1 mychannel ChannelConfig1 103809024 ${blockSize} 524288 2s`
      lastSettingTime = now
      console.log(command)
      exec(command)
    }
  })
}, 500)