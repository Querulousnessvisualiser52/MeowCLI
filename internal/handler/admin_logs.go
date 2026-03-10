package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

func (a *AdminHandler) ListLogs(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "50"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 200 {
		pageSize = 50
	}

	offset := int32((page - 1) * pageSize)

	total, err := a.countLogs(c.Request.Context())
	if err != nil {
		writeInternalError(c, err)
		return
	}

	rows, err := a.listLogs(c.Request.Context(), ListLogsParams{
		Limit:  int32(pageSize),
		Offset: offset,
	})
	if err != nil {
		writeInternalError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"total":     total,
		"page":      page,
		"page_size": pageSize,
		"data":      rows,
	})
}
