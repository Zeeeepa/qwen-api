"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var oas_1 = __importDefault(require("oas"));
var core_1 = __importDefault(require("api/dist/core"));
var openapi_json_1 = __importDefault(require("./openapi.json"));
var SDK = /** @class */ (function () {
    function SDK() {
        this.spec = oas_1.default.init(openapi_json_1.default);
        this.core = new core_1.default(this.spec, 'qwen-api/1.0.0 (api/6.1.3)');
    }
    /**
     * Optionally configure various options that the SDK allows.
     *
     * @param config Object of supported SDK options and toggles.
     * @param config.timeout Override the default `fetch` request timeout of 30 seconds. This number
     * should be represented in milliseconds.
     */
    SDK.prototype.config = function (config) {
        this.core.setConfig(config);
    };
    /**
     * If the API you're using requires authentication you can supply the required credentials
     * through this method and the library will magically determine how they should be used
     * within your API request.
     *
     * With the exception of OpenID and MutualTLS, it supports all forms of authentication
     * supported by the OpenAPI specification.
     *
     * @example <caption>HTTP Basic auth</caption>
     * sdk.auth('username', 'password');
     *
     * @example <caption>Bearer tokens (HTTP or OAuth 2)</caption>
     * sdk.auth('myBearerToken');
     *
     * @example <caption>API Keys</caption>
     * sdk.auth('myApiKey');
     *
     * @see {@link https://spec.openapis.org/oas/v3.0.3#fixed-fields-22}
     * @see {@link https://spec.openapis.org/oas/v3.1.0#fixed-fields-22}
     * @param values Your auth credentials for the API; can specify up to two strings or numbers.
     */
    SDK.prototype.auth = function () {
        var _a;
        var values = [];
        for (var _i = 0; _i < arguments.length; _i++) {
            values[_i] = arguments[_i];
        }
        (_a = this.core).setAuth.apply(_a, values);
        return this;
    };
    /**
     * If the API you're using offers alternate server URLs, and server variables, you can tell
     * the SDK which one to use with this method. To use it you can supply either one of the
     * server URLs that are contained within the OpenAPI definition (along with any server
     * variables), or you can pass it a fully qualified URL to use (that may or may not exist
     * within the OpenAPI definition).
     *
     * @example <caption>Server URL with server variables</caption>
     * sdk.server('https://{region}.api.example.com/{basePath}', {
     *   name: 'eu',
     *   basePath: 'v14',
     * });
     *
     * @example <caption>Fully qualified server URL</caption>
     * sdk.server('https://eu.api.example.com/v14');
     *
     * @param url Server URL
     * @param variables An object of variables to replace into the server URL.
     */
    SDK.prototype.server = function (url, variables) {
        if (variables === void 0) { variables = {}; }
        this.core.setServer(url, variables);
    };
    /**
     * List available models
     *
     * @throws FetchError<401, types.GetModelsResponse401> Unauthorized
     */
    SDK.prototype.getModels = function () {
        return this.core.fetch('/models', 'get');
    };
    /**
     * Validate compressed token (via request body)
     *
     * @throws FetchError<400, types.PostValidateResponse400> Bad request
     */
    SDK.prototype.postValidate = function (body) {
        return this.core.fetch('/validate', 'post', body);
    };
    /**
     * Validate compressed token (via query parameter)
     *
     * @throws FetchError<400, types.GetValidateResponse400> Bad request
     */
    SDK.prototype.getValidate = function (metadata) {
        return this.core.fetch('/validate', 'get', metadata);
    };
    /**
     * Refresh authentication token (via request body)
     *
     * @throws FetchError<400, types.PostRefreshResponse400> Bad request
     */
    SDK.prototype.postRefresh = function (body) {
        return this.core.fetch('/refresh', 'post', body);
    };
    /**
     * Refresh authentication token (via query parameter)
     *
     * @throws FetchError<400, types.GetRefreshResponse400> Bad request
     */
    SDK.prototype.getRefresh = function (metadata) {
        return this.core.fetch('/refresh', 'get', metadata);
    };
    /**
     * Create chat completion (OpenAI-compatible)
     *
     * @throws FetchError<400, types.PostChatCompletionsResponse400> Bad request
     * @throws FetchError<401, types.PostChatCompletionsResponse401> Unauthorized
     * @throws FetchError<500, types.PostChatCompletionsResponse500> Server error
     */
    SDK.prototype.postChatCompletions = function (body) {
        return this.core.fetch('/chat/completions', 'post', body);
    };
    /**
     * Generate an image from a text prompt
     *
     * @throws FetchError<400, types.PostImagesGenerationsResponse400> Bad request
     * @throws FetchError<401, types.PostImagesGenerationsResponse401> Unauthorized
     */
    SDK.prototype.postImagesGenerations = function (body) {
        return this.core.fetch('/images/generations', 'post', body);
    };
    /**
     * Edit an image using a prompt
     *
     * @throws FetchError<400, types.PostImagesEditsResponse400> Bad request
     * @throws FetchError<401, types.PostImagesEditsResponse401> Unauthorized
     */
    SDK.prototype.postImagesEdits = function (body) {
        return this.core.fetch('/images/edits', 'post', body);
    };
    /**
     * Generate a video from a text prompt
     *
     * @throws FetchError<400, types.PostVideosGenerationsResponse400> Bad request
     * @throws FetchError<401, types.PostVideosGenerationsResponse401> Unauthorized
     */
    SDK.prototype.postVideosGenerations = function (body) {
        return this.core.fetch('/videos/generations', 'post', body);
    };
    /**
     * Delete all chats (via DELETE method)
     *
     * @throws FetchError<401, types.DeleteChatsDeleteResponse401> Unauthorized
     * @throws FetchError<500, types.DeleteChatsDeleteResponse500> Server error
     */
    SDK.prototype.deleteChatsDelete = function () {
        return this.core.fetch('/chats/delete', 'delete');
    };
    /**
     * Delete all chats (via POST method)
     *
     * @throws FetchError<401, types.PostChatsDeleteResponse401> Unauthorized
     * @throws FetchError<500, types.PostChatsDeleteResponse500> Server error
     */
    SDK.prototype.postChatsDelete = function () {
        return this.core.fetch('/chats/delete', 'post');
    };
    return SDK;
}());
var createSDK = (function () { return new SDK(); })();
module.exports = createSDK;
