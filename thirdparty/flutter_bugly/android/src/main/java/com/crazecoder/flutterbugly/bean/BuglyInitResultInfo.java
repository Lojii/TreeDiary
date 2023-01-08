package com.crazecoder.flutterbugly.bean;

/**
 * Note of this class.
 *
 * @author crazecoder
 * @since 2019/3/4
 */
public class BuglyInitResultInfo {
    private String message;

    private String appId;

    private boolean isSuccess;

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getAppId() {
        return appId;
    }

    public void setAppId(String appId) {
        this.appId = appId;
    }

    public boolean isSuccess() {
        return isSuccess;
    }

    public void setSuccess(boolean success) {
        isSuccess = success;
    }
}
