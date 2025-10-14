declare const DeleteChatsDelete: {
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly properties: {
                readonly success: {
                    readonly type: "boolean";
                    readonly examples: readonly [true];
                };
                readonly message: {
                    readonly type: "string";
                    readonly examples: readonly ["All chats deleted successfully"];
                };
                readonly data: {
                    readonly type: "object";
                    readonly properties: {
                        readonly success: {
                            readonly type: "boolean";
                        };
                        readonly request_id: {
                            readonly type: "string";
                        };
                        readonly data: {
                            readonly type: "object";
                            readonly properties: {
                                readonly status: {
                                    readonly type: "boolean";
                                };
                            };
                        };
                    };
                };
            };
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "401": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "500": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const GetModels: {
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly properties: {
                readonly object: {
                    readonly type: "string";
                    readonly examples: readonly ["list"];
                };
                readonly data: {
                    readonly type: "array";
                    readonly items: {
                        readonly type: "object";
                        readonly properties: {
                            readonly id: {
                                readonly type: "string";
                            };
                            readonly object: {
                                readonly type: "string";
                                readonly examples: readonly ["model"];
                            };
                            readonly owned_by: {
                                readonly type: readonly ["string", "null"];
                            };
                        };
                        readonly required: readonly ["id", "object"];
                    };
                };
            };
            readonly required: readonly ["object", "data"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "401": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const GetRefresh: {
    readonly metadata: {
        readonly allOf: readonly [{
            readonly type: "object";
            readonly properties: {
                readonly token: {
                    readonly type: "string";
                    readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
                    readonly description: "Current token for refresh";
                };
            };
            readonly required: readonly ["token"];
        }];
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly description: "Upstream response passthrough";
            readonly additionalProperties: true;
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const GetValidate: {
    readonly metadata: {
        readonly allOf: readonly [{
            readonly type: "object";
            readonly properties: {
                readonly token: {
                    readonly type: "string";
                    readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
                    readonly description: "Compressed token from JS snippet";
                };
            };
            readonly required: readonly ["token"];
        }];
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly description: "Upstream response passthrough";
            readonly additionalProperties: true;
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const PostChatCompletions: {
    readonly body: {
        readonly type: "object";
        readonly properties: {
            readonly model: {
                readonly type: "string";
                readonly description: "Model ID (e.g., qwen-max-latest, qwen3-coder-plus, qwen-deep-research)";
                readonly examples: readonly ["qwen-max-latest"];
            };
            readonly messages: {
                readonly type: "array";
                readonly items: {
                    readonly type: "object";
                    readonly properties: {
                        readonly role: {
                            readonly type: "string";
                            readonly enum: readonly ["system", "user", "assistant", "tool"];
                            readonly examples: readonly ["user"];
                        };
                        readonly content: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "array";
                                readonly items: {
                                    readonly oneOf: readonly [{
                                        readonly type: "object";
                                        readonly properties: {
                                            readonly type: {
                                                readonly type: "string";
                                                readonly enum: readonly ["text"];
                                            };
                                            readonly text: {
                                                readonly type: "string";
                                            };
                                        };
                                        readonly required: readonly ["type", "text"];
                                    }, {
                                        readonly type: "object";
                                        readonly properties: {
                                            readonly type: {
                                                readonly type: "string";
                                                readonly enum: readonly ["image_url"];
                                            };
                                            readonly image_url: {
                                                readonly type: "object";
                                                readonly properties: {
                                                    readonly url: {
                                                        readonly type: "string";
                                                    };
                                                };
                                                readonly required: readonly ["url"];
                                            };
                                        };
                                        readonly required: readonly ["type", "image_url"];
                                    }, {
                                        readonly type: "object";
                                        readonly properties: {
                                            readonly type: {
                                                readonly type: "string";
                                                readonly enum: readonly ["audio_url"];
                                            };
                                            readonly audio_url: {
                                                readonly type: "object";
                                                readonly properties: {
                                                    readonly url: {
                                                        readonly type: "string";
                                                    };
                                                };
                                                readonly required: readonly ["url"];
                                            };
                                        };
                                        readonly required: readonly ["type", "audio_url"];
                                    }, {
                                        readonly type: "object";
                                        readonly properties: {
                                            readonly type: {
                                                readonly type: "string";
                                                readonly enum: readonly ["video_url"];
                                            };
                                            readonly video_url: {
                                                readonly type: "object";
                                                readonly properties: {
                                                    readonly url: {
                                                        readonly type: "string";
                                                    };
                                                };
                                                readonly required: readonly ["url"];
                                            };
                                        };
                                        readonly required: readonly ["type", "video_url"];
                                    }, {
                                        readonly type: "object";
                                        readonly properties: {
                                            readonly type: {
                                                readonly type: "string";
                                                readonly enum: readonly ["file_url"];
                                            };
                                            readonly file_url: {
                                                readonly type: "object";
                                                readonly properties: {
                                                    readonly url: {
                                                        readonly type: "string";
                                                    };
                                                };
                                                readonly required: readonly ["url"];
                                            };
                                        };
                                        readonly required: readonly ["type", "file_url"];
                                    }];
                                };
                            }];
                        };
                    };
                    readonly required: readonly ["role", "content"];
                };
            };
            readonly stream: {
                readonly type: "boolean";
                readonly default: false;
            };
            readonly tools: {
                readonly type: "array";
                readonly items: {
                    readonly type: "object";
                    readonly properties: {
                        readonly type: {
                            readonly type: "string";
                            readonly enum: readonly ["web_search", "code"];
                        };
                    };
                    readonly required: readonly ["type"];
                };
            };
            readonly enable_thinking: {
                readonly type: "boolean";
                readonly description: "Enable reasoning/thinking mode";
            };
            readonly thinking_budget: {
                readonly type: "integer";
                readonly description: "Thinking budget in ms";
            };
        };
        readonly required: readonly ["model", "messages"];
        readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly properties: {
                readonly id: {
                    readonly type: "string";
                };
                readonly object: {
                    readonly type: "string";
                    readonly examples: readonly ["chat.completion"];
                };
                readonly created: {
                    readonly type: "integer";
                };
                readonly model: {
                    readonly type: "string";
                };
                readonly system_fingerprint: {
                    readonly type: "string";
                };
                readonly choices: {
                    readonly type: "array";
                    readonly items: {
                        readonly type: "object";
                        readonly properties: {
                            readonly index: {
                                readonly type: "integer";
                            };
                            readonly message: {
                                readonly type: "object";
                                readonly properties: {
                                    readonly role: {
                                        readonly type: "string";
                                    };
                                    readonly content: {
                                        readonly type: "string";
                                    };
                                    readonly reasoning_content: {
                                        readonly type: "string";
                                    };
                                };
                                readonly required: readonly ["role", "content"];
                            };
                            readonly finish_reason: {
                                readonly type: readonly ["string", "null"];
                            };
                        };
                        readonly required: readonly ["index", "message"];
                    };
                };
            };
            readonly required: readonly ["id", "object", "created", "model", "choices"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "401": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "500": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const PostChatsDelete: {
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly properties: {
                readonly success: {
                    readonly type: "boolean";
                    readonly examples: readonly [true];
                };
                readonly message: {
                    readonly type: "string";
                    readonly examples: readonly ["All chats deleted successfully"];
                };
                readonly data: {
                    readonly type: "object";
                    readonly properties: {
                        readonly success: {
                            readonly type: "boolean";
                        };
                        readonly request_id: {
                            readonly type: "string";
                        };
                        readonly data: {
                            readonly type: "object";
                            readonly properties: {
                                readonly status: {
                                    readonly type: "boolean";
                                };
                            };
                        };
                    };
                };
            };
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "401": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "500": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const PostImagesEdits: {
    readonly body: {
        readonly type: "object";
        readonly properties: {
            readonly prompt: {
                readonly type: "string";
                readonly examples: readonly ["Add a rainbow in the background"];
            };
            readonly image: {
                readonly oneOf: readonly [{
                    readonly type: "string";
                    readonly format: "uri";
                    readonly description: "Remote image URL";
                }, {
                    readonly type: "string";
                    readonly description: "Data URL base64 image";
                }];
                readonly examples: readonly ["https://example.com/image.jpg"];
            };
        };
        readonly required: readonly ["prompt", "image"];
        readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly properties: {
                readonly created: {
                    readonly type: "integer";
                };
                readonly data: {
                    readonly type: "array";
                    readonly items: {
                        readonly type: "object";
                        readonly properties: {
                            readonly url: {
                                readonly type: "string";
                            };
                        };
                        readonly required: readonly ["url"];
                    };
                };
            };
            readonly required: readonly ["created", "data"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "401": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const PostImagesGenerations: {
    readonly body: {
        readonly type: "object";
        readonly properties: {
            readonly prompt: {
                readonly type: "string";
                readonly examples: readonly ["A beautiful sunset over mountains"];
            };
            readonly size: {
                readonly type: "string";
                readonly description: "Target size; proxy maps to aspect ratio";
                readonly examples: readonly ["1024x1024"];
            };
        };
        readonly required: readonly ["prompt"];
        readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly properties: {
                readonly created: {
                    readonly type: "integer";
                };
                readonly data: {
                    readonly type: "array";
                    readonly items: {
                        readonly type: "object";
                        readonly properties: {
                            readonly url: {
                                readonly type: "string";
                            };
                        };
                        readonly required: readonly ["url"];
                    };
                };
            };
            readonly required: readonly ["created", "data"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "401": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const PostRefresh: {
    readonly body: {
        readonly type: "object";
        readonly properties: {
            readonly token: {
                readonly type: "string";
                readonly description: "Compressed token produced by the README JS snippet";
            };
        };
        readonly required: readonly ["token"];
        readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly description: "Upstream response passthrough";
            readonly additionalProperties: true;
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const PostValidate: {
    readonly body: {
        readonly type: "object";
        readonly properties: {
            readonly token: {
                readonly type: "string";
                readonly description: "Compressed token produced by the README JS snippet";
            };
        };
        readonly required: readonly ["token"];
        readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly description: "Upstream response passthrough";
            readonly additionalProperties: true;
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
declare const PostVideosGenerations: {
    readonly body: {
        readonly type: "object";
        readonly properties: {
            readonly prompt: {
                readonly type: "string";
                readonly examples: readonly ["A cat playing with a ball of yarn in slow motion"];
            };
            readonly size: {
                readonly type: "string";
                readonly description: "Target size; proxy maps to aspect ratio";
                readonly examples: readonly ["1024x1024"];
            };
        };
        readonly required: readonly ["prompt"];
        readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
    };
    readonly response: {
        readonly "200": {
            readonly type: "object";
            readonly properties: {
                readonly created: {
                    readonly type: "integer";
                };
                readonly data: {
                    readonly type: "array";
                    readonly items: {
                        readonly type: "object";
                        readonly properties: {
                            readonly url: {
                                readonly type: "string";
                            };
                        };
                        readonly required: readonly ["url"];
                    };
                };
            };
            readonly required: readonly ["created", "data"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "400": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
        readonly "401": {
            readonly type: "object";
            readonly properties: {
                readonly error: {
                    readonly type: "object";
                    readonly properties: {
                        readonly message: {
                            readonly type: "string";
                        };
                        readonly type: {
                            readonly type: "string";
                        };
                        readonly param: {
                            readonly type: readonly ["string", "null"];
                        };
                        readonly code: {
                            readonly oneOf: readonly [{
                                readonly type: "string";
                            }, {
                                readonly type: "integer";
                            }];
                        };
                    };
                    readonly required: readonly ["message", "type", "code"];
                };
            };
            readonly required: readonly ["error"];
            readonly $schema: "https://json-schema.org/draft/2020-12/schema#";
        };
    };
};
export { DeleteChatsDelete, GetModels, GetRefresh, GetValidate, PostChatCompletions, PostChatsDelete, PostImagesEdits, PostImagesGenerations, PostRefresh, PostValidate, PostVideosGenerations };
