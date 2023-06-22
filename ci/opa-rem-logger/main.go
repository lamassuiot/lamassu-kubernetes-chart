package main

import (
	"compress/gzip"
	"encoding/json"
	"io"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/open-policy-agent/opa/plugins/logs"
	log "github.com/sirupsen/logrus"
)

type EventInput struct {
	Attributes struct {
		Request struct {
			Http struct {
				Path   string `json:"path"`
				Method string `json:"method"`
			} `json:"http"`
			Timestamp string `json:"time"`
		} `json:"request"`
	} `json:"attributes"`
}

func main() {
	debugEnv := os.Getenv("DEBUG")
	customFormatter := new(log.JSONFormatter)
	customFormatter.PrettyPrint = true
	// customFormatter.DisableTimestamp = true
	log.SetFormatter(customFormatter)

	router := gin.Default()
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowAllOrigins = true
	corsConfig.AllowHeaders = []string{"*"}

	router.Use(cors.New(corsConfig))

	router.POST("/logs", func(c *gin.Context) {
		var requestBody []logs.EventV1
		r, err := gzip.NewReader(c.Request.Body)
		if err != nil {
			log.Errorf("error while reading gzip encoded body: %s", err)
			return
		}
		raw, err := io.ReadAll(r)
		if err != nil {
			log.Errorf("error while reading decoded body: %s", err)
			return
		}

		json.Unmarshal(raw, &requestBody)
		for _, event := range requestBody {
			resultIfce := *event.Result
			if castedResult, ok := resultIfce.(bool); ok {
				action := "ALLOW"
				if !castedResult {
					action = "DENY"
				}

				inputIfce := *event.Input
				var eventInput EventInput
				b, _ := json.Marshal(inputIfce)
				json.Unmarshal(b, &eventInput)
				logEntry := log.WithFields(log.Fields{
					"method": eventInput.Attributes.Request.Http.Method,
					"path":   eventInput.Attributes.Request.Http.Path,
					"@time":  eventInput.Attributes.Request.Timestamp,
				})

				if debugEnv != "" {
					logEntry = logEntry.WithField("raw_input", string(b))
				}

				logEntry.Info(action)
			}
		}

		c.JSON(http.StatusOK, gin.H{})
	})

	log.Info("running HTTP server on 0.0.0.0:8080")
	router.Run("0.0.0.0:8080") // listen and serve on 0.0.0.0:8080 (for windows "localhost:8080")
}
