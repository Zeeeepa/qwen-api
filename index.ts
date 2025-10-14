import type * as types from './types';
import type { ConfigOptions, FetchResponse } from 'api/dist/core'
import Oas from 'oas';
import APICore from 'api/dist/core';
import definition from './openapi.json';

class SDK {
  spec: Oas;
  core: APICore;

  constructor() {
    this.spec = Oas.init(definition);
    this.core = new APICore(this.spec, 'qwen-api/1.0.0 (api/6.1.3)');
  }

  /**
   * Optionally configure various options that the SDK allows.
   *
   * @param config Object of supported SDK options and toggles.
   * @param config.timeout Override the default `fetch` request timeout of 30 seconds. This number
   * should be represented in milliseconds.
   */
  config(config: ConfigOptions) {
    this.core.setConfig(config);
  }

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
  auth(...values: string[] | number[]) {
    this.core.setAuth(...values);
    return this;
  }

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
  server(url: string, variables = {}) {
    this.core.setServer(url, variables);
  }

  /**
   * List available models
   *
   * @throws FetchError<401, types.GetModelsResponse401> Unauthorized
   */
  getModels(): Promise<FetchResponse<200, types.GetModelsResponse200>> {
    return this.core.fetch('/models', 'get');
  }

  /**
   * Validate compressed token (via request body)
   *
   * @throws FetchError<400, types.PostValidateResponse400> Bad request
   */
  postValidate(body: types.PostValidateBodyParam): Promise<FetchResponse<200, types.PostValidateResponse200>> {
    return this.core.fetch('/validate', 'post', body);
  }

  /**
   * Validate compressed token (via query parameter)
   *
   * @throws FetchError<400, types.GetValidateResponse400> Bad request
   */
  getValidate(metadata: types.GetValidateMetadataParam): Promise<FetchResponse<200, types.GetValidateResponse200>> {
    return this.core.fetch('/validate', 'get', metadata);
  }

  /**
   * Refresh authentication token (via request body)
   *
   * @throws FetchError<400, types.PostRefreshResponse400> Bad request
   */
  postRefresh(body: types.PostRefreshBodyParam): Promise<FetchResponse<200, types.PostRefreshResponse200>> {
    return this.core.fetch('/refresh', 'post', body);
  }

  /**
   * Refresh authentication token (via query parameter)
   *
   * @throws FetchError<400, types.GetRefreshResponse400> Bad request
   */
  getRefresh(metadata: types.GetRefreshMetadataParam): Promise<FetchResponse<200, types.GetRefreshResponse200>> {
    return this.core.fetch('/refresh', 'get', metadata);
  }

  /**
   * Create chat completion (OpenAI-compatible)
   *
   * @throws FetchError<400, types.PostChatCompletionsResponse400> Bad request
   * @throws FetchError<401, types.PostChatCompletionsResponse401> Unauthorized
   * @throws FetchError<500, types.PostChatCompletionsResponse500> Server error
   */
  postChatCompletions(body: types.PostChatCompletionsBodyParam): Promise<FetchResponse<200, types.PostChatCompletionsResponse200>> {
    return this.core.fetch('/chat/completions', 'post', body);
  }

  /**
   * Generate an image from a text prompt
   *
   * @throws FetchError<400, types.PostImagesGenerationsResponse400> Bad request
   * @throws FetchError<401, types.PostImagesGenerationsResponse401> Unauthorized
   */
  postImagesGenerations(body: types.PostImagesGenerationsBodyParam): Promise<FetchResponse<200, types.PostImagesGenerationsResponse200>> {
    return this.core.fetch('/images/generations', 'post', body);
  }

  /**
   * Edit an image using a prompt
   *
   * @throws FetchError<400, types.PostImagesEditsResponse400> Bad request
   * @throws FetchError<401, types.PostImagesEditsResponse401> Unauthorized
   */
  postImagesEdits(body: types.PostImagesEditsBodyParam): Promise<FetchResponse<200, types.PostImagesEditsResponse200>> {
    return this.core.fetch('/images/edits', 'post', body);
  }

  /**
   * Generate a video from a text prompt
   *
   * @throws FetchError<400, types.PostVideosGenerationsResponse400> Bad request
   * @throws FetchError<401, types.PostVideosGenerationsResponse401> Unauthorized
   */
  postVideosGenerations(body: types.PostVideosGenerationsBodyParam): Promise<FetchResponse<200, types.PostVideosGenerationsResponse200>> {
    return this.core.fetch('/videos/generations', 'post', body);
  }

  /**
   * Delete all chats (via DELETE method)
   *
   * @throws FetchError<401, types.DeleteChatsDeleteResponse401> Unauthorized
   * @throws FetchError<500, types.DeleteChatsDeleteResponse500> Server error
   */
  deleteChatsDelete(): Promise<FetchResponse<200, types.DeleteChatsDeleteResponse200>> {
    return this.core.fetch('/chats/delete', 'delete');
  }

  /**
   * Delete all chats (via POST method)
   *
   * @throws FetchError<401, types.PostChatsDeleteResponse401> Unauthorized
   * @throws FetchError<500, types.PostChatsDeleteResponse500> Server error
   */
  postChatsDelete(): Promise<FetchResponse<200, types.PostChatsDeleteResponse200>> {
    return this.core.fetch('/chats/delete', 'post');
  }
}

const createSDK = (() => { return new SDK(); })()
;

export default createSDK;

export type { DeleteChatsDeleteResponse200, DeleteChatsDeleteResponse401, DeleteChatsDeleteResponse500, GetModelsResponse200, GetModelsResponse401, GetRefreshMetadataParam, GetRefreshResponse200, GetRefreshResponse400, GetValidateMetadataParam, GetValidateResponse200, GetValidateResponse400, PostChatCompletionsBodyParam, PostChatCompletionsResponse200, PostChatCompletionsResponse400, PostChatCompletionsResponse401, PostChatCompletionsResponse500, PostChatsDeleteResponse200, PostChatsDeleteResponse401, PostChatsDeleteResponse500, PostImagesEditsBodyParam, PostImagesEditsResponse200, PostImagesEditsResponse400, PostImagesEditsResponse401, PostImagesGenerationsBodyParam, PostImagesGenerationsResponse200, PostImagesGenerationsResponse400, PostImagesGenerationsResponse401, PostRefreshBodyParam, PostRefreshResponse200, PostRefreshResponse400, PostValidateBodyParam, PostValidateResponse200, PostValidateResponse400, PostVideosGenerationsBodyParam, PostVideosGenerationsResponse200, PostVideosGenerationsResponse400, PostVideosGenerationsResponse401 } from './types';
