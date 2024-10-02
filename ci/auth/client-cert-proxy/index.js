var http = require('http'),
    httpProxy = require('http-proxy');

var proxy = httpProxy.createProxyServer({});

proxy.on('proxyReq', function (proxyReq, req, res, options) {
    proxyReq.setHeader('X-Special-Proxy-Header', 'foobar');

    // transform Envoy client certificate to Nginx style since keycloak does not recognize envoy cert header(using ssl-client-cert header)
    if (proxyReq.hasHeader("x-forwarded-client-cert")) {
        // let envoyCert=`Hash=9def1c1c6d6a7eb670aaf141c126ddb001a63a9c9203cb9e3bc7ca4b746c3d60;Chain="-----BEGIN%20CERTIFICATE-----%0AMIIDdTCCAxygAwIBAgIQX0L1bVPmFg5lLX1OuqlA0jAKBggqhkjOPQQDAjBnMQsw%0ACQYDVQQGEwJFUzERMA8GA1UECBMIR2lwdXprb2ExEDAOBgNVBAcTB0JlYXNhaW4x%0AEjAQBgNVBAoTCUdIIENyYW5lczEfMB0GA1UEAxMWR0ggQ29yZWJveCBJZGVudGl0%0AeSBDQTAeFw0yNDA3MTcxMDUwMDNaFw0yNjA3MTUxMDUwMDNaMDUxCzAJBgNVBAYT%0AAkVTMRIwEAYDVQQKEwlHSCBDcmFuZXMxEjAQBgNVBAMTCUNvcmVib3gtMTCCASIw%0ADQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKmEIfcVbkcwH0%2Bij9yCapYoWfzK%0A%2FUBIlYtaLMRqeFPT84ajjDcGrqcLvbJFifjyPzWnN4pl4enpdygHPaKVQC5ryWKS%0ACbGwlbDhgDfv%2B2eah1J6mp%2Bk9Hnll2AyrpIkQ2nSAvFLFSwwU7l3yccJqfozHPwP%0A%2FCDpupljivM3kk1mPcZn5IkzeIQBxDcGP%2FV2cTjSxx6viClMWXbQs48ub1WDp%2Bu6%0AaB8fyTOSlPqSTartP0QMnyHmPOIASm6zrQ36aWRrMuYOaIokwGcLogluMzW8L8nz%0AwJo9qi6%2FI5mDCHOz7K3a8ybuQmtjATVjz1cCNxyLT76UKAvBg94j6sBb51UCAwEA%0AAaOCAQ8wggELMA4GA1UdDwEB%2FwQEAwIHgDAdBgNVHSUEFjAUBggrBgEFBQcDAgYI%0AKwYBBQUHAwEwLwYDVR0jBCgwJoAkZDEwM2YzODQtNDc0Ny00NWFhLTllYzEtNTE5%0AMTM4NTY0ZjMyMEcGCCsGAQUFBwEBBDswOTA3BggrBgEFBQcwAYYraHR0cHM6Ly9s%0AYW1zc3UtZGV2LmdoY3JhbmVzLmNvbS9hcGkvdmEvb2NzcDBgBgNVHR8EWTBXMFWg%0AU6BRhk9odHRwczovL2xhbXNzdS1kZXYuZ2hjcmFuZXMuY29tL2FwaS92YS9jcmwv%0AZDEwM2YzODQtNDc0Ny00NWFhLTllYzEtNTE5MTM4NTY0ZjMyMAoGCCqGSM49BAMC%0AA0cAMEQCH0396JDIrwFBsYkHW7g937mpyNWpZhJIxw8x3V4GWvwCIQC5JoFSNyzg%0ALo20QMYX7P2DU0B0smz1u5%2B7cYWl39PiOQ%3D%3D%0A-----END%20CERTIFICATE-----%0A"`
        let envoyCert = proxyReq.getHeader("x-forwarded-client-cert");
        let clientCert = envoyCert.split(";")[1].split("=")[1].replaceAll("\"", "");
        console.log("Request has client cert. Setting ssl-client-cert header to " + clientCert);
        proxyReq.setHeader("ssl-client-cert", clientCert);
    }
});

var server = http.createServer(function (req, res) {
    console.log(req.url);
    proxy.web(req, res, {
        target: process.env.TARGET_PROTOCOL + "://" + process.env.TARGET_HOST + ":" + process.env.TARGET_PORT,
        secure: false
    });
});

console.log("proxy listening on port " + process.env.PROXY_PORT);
// server.listen(5000, "0.0.0.0");
server.listen(process.env.PROXY_PORT, "0.0.0.0");