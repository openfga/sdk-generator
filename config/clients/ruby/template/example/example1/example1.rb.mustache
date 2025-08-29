#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'openfga', '~> 0.0.1', path: File.expand_path('../../../', __dir__)
  gem 'logger'
  gem 'ulid'
end

# OpenFGA Ruby SDK Example
# This example demonstrates how to use the OpenFGA Ruby SDK to interact with an OpenFGA server.
class OpenFgaExample
  def initialize
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO

    # Initialize the OpenFGA client
    # Replace with your OpenFGA server URL
    @client = OpenFga::SdkClient.new(
      api_url: ENV.fetch('OPENFGA_API_URL', 'http://localhost:8080'),
      store_id: nil # Will be set after creating a store
    )

    @store_id = nil
    @authorization_model_id = nil
  end

  def run
    @logger.info 'Starting OpenFGA Ruby SDK Example'

    # 0. Test connection first
    return unless connection_active?

    # 1. Store Management
    create_store_example
    list_stores_example
    get_store_example

    # 2. Authorization Models
    write_authorization_model_example
    read_authorization_model_example
    read_authorization_models_example

    # 3. Relationship Tuples
    write_tuples_example
    read_tuples_example

    # 4. Authorization Checks
    check_example
    batch_check_example

    # 5. Advanced Queries
    expand_example

    # 6. Tuple Changes
    read_changes_example

    # 7. Assertions
    write_assertions_example
    read_assertions_example

    # 8. Cleanup
    delete_store_example

    @logger.info 'OpenFGA Ruby SDK Example completed successfully!'
  rescue => e
    @logger.error "Example failed: #{e.message}"
    @logger.error e.backtrace.join("\n")
    raise e
  end

  private

    def connection_active?
      @logger.info '=== Testing Connection to OpenFGA Server ==='

      begin
        # Perform a simple check to test the connection
        response = @client.list_stores
        @logger.info "Connection test successful. Found #{response.stores.length} stores."
        true
      rescue => e
        @logger.error "Connection test failed, is OpenFGA running? -> #{e.message}"
        false
      end
    end

    def create_store_example
      @logger.info '=== Creating Store ==='

      store_name = "Example Store #{Time.now.to_i}"
      response = @client.create_store(name: store_name)

      @store_id = response.id
      @logger.info "Created store: #{@store_id}"

      # Update client with store_id
      @client = OpenFga::SdkClient.new(
        api_url: ENV.fetch('OPENFGA_API_URL', 'http://localhost:8080'),
        store_id: @store_id
      )
    end

    def list_stores_example
      @logger.info '=== Listing Stores ==='

      response = @client.list_stores
      @logger.info "Found #{response.stores.length} stores"

      response.stores.each do |store|
        @logger.info "  Store: #{store.name} (#{store.id})"
      end
    end

    def get_store_example
      @logger.info '=== Getting Store ==='

      response = @client.get_store
      @logger.info "Store details: #{response.name} (#{response.id})"
    end

    def write_authorization_model_example
      @logger.info '=== Writing Authorization Model ==='

      # Define a sample authorization model for a document management system
      authorization_model = {
        schema_version: '1.1',
        type_definitions: [
          {
            type: 'user',
            relations: {},
            metadata: nil
          },
          {
            type: 'organization',
            relations: {
              member: {
                union: {
                  child: [
                    {
                      this: {}
                    },
                    {
                      computed_userset: {
                        object: '',
                        relation: 'owner'
                      }
                    }
                  ]
                }
              },
              owner: {
                this: {}
              },
              repo_admin: {
                this: {}
              },
              repo_reader: {
                this: {}
              },
              repo_writer: {
                this: {}
              }
            },
            metadata: {
              relations: {
                member: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                owner: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                repo_admin: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'organization',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                repo_reader: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'organization',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                repo_writer: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'organization',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                }
              },
              module: '',
              source_info: nil
            }
          },
          {
            type: 'team',
            relations: {
              member: {
                this: {}
              }
            },
            metadata: {
              relations: {
                member: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'team',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                }
              },
              module: '',
              source_info: nil
            }
          },
          {
            type: 'repo',
            relations: {
              owner: {
                this: {}
              },
              admin: {
                union: {
                  child: [
                    {
                      this: {}
                    },
                    {
                      tuple_to_userset: {
                        tupleset: {
                          object: '',
                          relation: 'owner'
                        },
                        computed_userset: {
                          object: '',
                          relation: 'repo_admin'
                        }
                      }
                    }
                  ]
                }
              },
              maintainer: {
                union: {
                  child: [
                    {
                      this: {}
                    },
                    {
                      computed_userset: {
                        object: '',
                        relation: 'admin'
                      }
                    }
                  ]
                }
              },
              writer: {
                union: {
                  child: [
                    {
                      this: {}
                    },
                    {
                      computed_userset: {
                        object: '',
                        relation: 'maintainer'
                      }
                    },
                    {
                      tuple_to_userset: {
                        tupleset: {
                          object: '',
                          relation: 'owner'
                        },
                        computed_userset: {
                          object: '',
                          relation: 'repo_writer'
                        }
                      }
                    }
                  ]
                }
              },
              triager: {
                union: {
                  child: [
                    {
                      this: {}
                    },
                    {
                      computed_userset: {
                        object: '',
                        relation: 'writer'
                      }
                    }
                  ]
                }
              },
              reader: {
                union: {
                  child: [
                    {
                      this: {}
                    },
                    {
                      computed_userset: {
                        object: '',
                        relation: 'triager'
                      }
                    },
                    {
                      tuple_to_userset: {
                        tupleset: {
                          object: '',
                          relation: 'owner'
                        },
                        computed_userset: {
                          object: '',
                          relation: 'repo_reader'
                        }
                      }
                    }
                  ]
                }
              }
            },
            metadata: {
              relations: {
                owner: {
                  directly_related_user_types: [
                    {
                      type: 'organization',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                admin: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'team',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                maintainer: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'team',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                writer: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'team',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                triager: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'team',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                },
                reader: {
                  directly_related_user_types: [
                    {
                      type: 'user',
                      condition: ''
                    },
                    {
                      type: 'team',
                      relation: 'member',
                      condition: ''
                    }
                  ],
                  module: '',
                  source_info: nil
                }
              },
              module: '',
              source_info: nil
            }
          }
        ],
        conditions: {}
      }

      response = @client.write_authorization_model(**authorization_model)
      @authorization_model_id = response.authorization_model_id
      @logger.info "Created authorization model: #{@authorization_model_id}"
    end

    def read_authorization_model_example
      @logger.info '=== Reading Authorization Model ==='

      response = @client.read_authorization_model(id: @authorization_model_id)
      @logger.info "Authorization model ID: #{response.authorization_model.id}"
      @logger.info "Schema version: #{response.authorization_model.schema_version}"
      @logger.info "Type definitions count: #{response.authorization_model.type_definitions.length}"
    end

    def read_authorization_models_example
      @logger.info '=== Reading All Authorization Models ==='

      response = @client.read_authorization_models
      @logger.info "Found #{response.authorization_models.length} authorization models"

      response.authorization_models.each do |model|
        @logger.info "  Model: #{model.id} (schema: #{model.schema_version})"
      end
    end

    def write_tuples_example
      @logger.info '=== Writing Relationship Tuples ==='

      # Write some sample relationships for GitHub-like repository system
      writes = {
          tuple_keys: [
            # Create an organization and add users
            {
              user: 'user:alice',
              relation: 'owner',
              object: 'organization:github'
            },
            {
              user: 'user:bob',
              relation: 'member',
              object: 'organization:github'
            },
            {
              user: 'user:charlie',
              relation: 'repo_admin',
              object: 'organization:github'
            },
            {
              user: 'user:dave',
              relation: 'repo_writer',
              object: 'organization:github'
            },
            {
              user: 'user:eve',
              relation: 'repo_reader',
              object: 'organization:github'
            },

            # Create teams and add members
            {
              user: 'user:alice',
              relation: 'member',
              object: 'team:core'
            },
            {
              user: 'user:bob',
              relation: 'member',
              object: 'team:core'
            },
            {
              user: 'user:charlie',
              relation: 'member',
              object: 'team:frontend'
            },
            {
              user: 'user:dave',
              relation: 'member',
              object: 'team:backend'
            },

            # Create repositories and assign ownership
            {
              user: 'organization:github',
              relation: 'owner',
              object: 'repo:ruby-sdk'
            },
            {
              user: 'organization:github',
              relation: 'owner',
              object: 'repo:python-sdk'
            },

            # Assign repository-specific permissions
            {
              user: 'user:alice',
              relation: 'admin',
              object: 'repo:ruby-sdk'
            },
            {
              user: 'team:core#member',
              relation: 'maintainer',
              object: 'repo:ruby-sdk'
            },
            {
              user: 'user:charlie',
              relation: 'writer',
              object: 'repo:python-sdk'
            },
            {
              user: 'team:frontend#member',
              relation: 'triager',
              object: 'repo:ruby-sdk'
            },
            {
              user: 'team:backend#member',
              relation: 'reader',
              object: 'repo:python-sdk'
            }
          ]
      }

      @client.write(writes:, opts: { authorization_model_id: @authorization_model_id })
      @logger.info "Successfully wrote #{writes[:tuple_keys].length} tuples"
    end

    def read_tuples_example
      @logger.info '=== Reading Relationship Tuples ==='

      # Read all tuples for repo:ruby-sdk
      response = @client.read(object: 'repo:ruby-sdk', opts: { authorization_model_id: @authorization_model_id })

      @logger.info "Found #{response.tuples.length} tuples for repo:ruby-sdk:"
      response.tuples.each do |tuple|
        @logger.info "  #{tuple.key.user} -> #{tuple.key.relation} -> #{tuple.key.object}"
      end
    end

    def check_example
      @logger.info '=== Authorization Checks ==='

      # Check if Alice can read repo:ruby-sdk (should be true - she's an admin)
      response = @client.check(
        user: 'user:alice',
        relation: 'reader',
        object: 'repo:ruby-sdk',
        opts: { authorization_model_id: @authorization_model_id }
      )
      @logger.info "Can Alice read repo:ruby-sdk? #{response.allowed}"

      # Check if Bob can write repo:ruby-sdk (should be true - he's in core team which has maintainer access)
      response = @client.check(
        user: 'user:bob',
        relation: 'writer',
        object: 'repo:ruby-sdk',
        opts: { authorization_model_id: @authorization_model_id }
      )
      @logger.info "Can Bob write repo:ruby-sdk? #{response.allowed}"

      # Check if Charlie can admin repo:ruby-sdk (should be false - he only has writer access to python-sdk)
      response = @client.check(
        user: 'user:charlie',
        relation: 'admin',
        object: 'repo:ruby-sdk',
        opts: { authorization_model_id: @authorization_model_id }
      )
      @logger.info "Can Charlie admin repo:ruby-sdk? #{response.allowed}"

      # Check if Dave can read repo:python-sdk (should be true - he's in backend team + org repo_writer permission)
      response = @client.check(
        user: 'user:dave',
        relation: 'reader',
        object: 'repo:python-sdk',
        opts: { authorization_model_id: @authorization_model_id }
      )
      @logger.info "Can Dave read repo:python-sdk? #{response.allowed}"

      # Check if Eve can write repo:ruby-sdk (should be false - she only has org repo_reader permission)
      response = @client.check(
        user: 'user:eve',
        relation: 'writer',
        object: 'repo:ruby-sdk',
        opts: { authorization_model_id: @authorization_model_id }
      )
      @logger.info "Can Eve write repo:ruby-sdk? #{response.allowed}"
    end

    def batch_check_example
      @logger.info '=== Batch Check ==='

      @logger.info 'Sending a batch check request'
      response = @client.batch_check(
        checks: [
          {
            tuple_key: {
              user: 'user:alice',
              relation: :reader,
              object: 'repo:ruby-sdk',
            },
            correlation_id: ULID.generate
          },
          {
            tuple_key: {
              user: 'user:eve',
              relation: :writer,
              object: 'repo:python-sdk',
            },
            correlation_id: ULID.generate
          },
          {
            tuple_key: {
              user: 'user:dave',
              relation: :reader,
              object: 'repo:python-sdk',
            },
            correlation_id: ULID.generate
          }
        ],
        opts: {
          authorization_model_id: @authorization_model_id,
          max_batch_size: 100,
          max_parallel_requests: 10
        }
      )

      @logger.info "Batch check completed with #{response.result.length} results"

      response.result.each do |correlation_id, result|
        @logger.info "  Correlation ID: #{correlation_id} - Allowed: #{result.allowed}"

        if result.error
          @logger.error "    Error: #{result.error.message}"
        end
      end
    end

    def expand_example
      @logger.info '=== Expanding Relationships ==='

      # Expand who has reader access to repo:ruby-sdk
      response = @client.expand(
        relation: 'reader',
        object: 'repo:ruby-sdk',
        opts: { authorization_model_id: @authorization_model_id }
      )

      @logger.info 'Users with reader access to repo:ruby-sdk:'
      @logger.info "Expansion tree: #{response.tree.root.name}"

      # Note: The actual expansion tree structure would need more detailed parsing
      # This is a simplified representation
    end

    def read_changes_example
      @logger.info '=== Reading Tuple Changes ==='

      # Read recent changes to the store
      response = @client.read_changes(type: 'document', start_time: '2022-01-01T00:00:00Z')

      @logger.info "Found #{response.changes.length} recent changes:"
      response.changes.each do |change|
        @logger.info "  #{change.operation}: #{change.tuple_key.user} -> #{change.tuple_key.relation} -> #{change.tuple_key.object}"
      end
    end

    def write_assertions_example
      @logger.info '=== Writing Assertions ==='

      # Define assertions to test our authorization model
      assertions = [
        {
          tuple_key: {
            user: 'user:alice',
            relation: 'reader',
            object: 'repo:ruby-sdk'
          },
          expectation: true
        },
        {
          tuple_key: {
            user: 'user:eve',
            relation: 'admin',
            object: 'repo:ruby-sdk'
          },
          expectation: false
        },
        {
          tuple_key: {
            user: 'user:bob',
            relation: 'writer',
            object: 'repo:ruby-sdk'
          },
          expectation: true
        }
      ]

      @client.write_assertions(assertions:,
                               opts: { authorization_model_id: @authorization_model_id })

      @logger.info "Successfully wrote #{assertions.length} assertions"
    end

    def read_assertions_example
      @logger.info '=== Reading Assertions ==='

      response = @client.read_assertions(authorization_model_id: @authorization_model_id)

      @logger.info "Found #{response.assertions.length} assertions:"
      response.assertions.each do |assertion|
        @logger.info "  #{assertion.tuple_key.user} -> #{assertion.tuple_key.relation} -> #{assertion.tuple_key.object}: expected #{assertion.expectation}"
      end
    end

    def delete_store_example
      @logger.info '=== Deleting Store ==='

      @client.delete_store
      @logger.info "Deleted store: #{@store_id}"
    end
end

# Run the example if this file is executed directly
if __FILE__ == $0
  example = OpenFgaExample.new
  example.run
end
