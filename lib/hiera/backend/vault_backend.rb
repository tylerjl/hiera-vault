# Vault backend for Hiera
class Hiera
  module Backend
    class Vault_backend

      def initialize()
        require 'json'
        require 'vault'

        @config = Config[:vault]
        @vault = Vault::Client.new(address: @config[:addr], token: @config[:token])
        Hiera.debug("[hiera-vault] Client configured to connect to #{@vault.address}")
      end

      def lookup(key, scope, order_override, resolution_type)
        begin
          secret = @vault.logical.read(key)
          Hiera.debug("[hiera-vault] Read secret: #{key}")

        rescue Vault::HTTPConnectionError
          Hiera.warn("[hiera-vault] Could not connect to read secret: #{key}")
        rescue Vault::HTTPError => e
          Hiera.warn("[hiera-vault] Could not read secret #{key}: #{e.errors.join("\n").rstrip}")
        end

        return nil if secret.nil?

        # Turn secret's hash keys into strings
        data = secret.data.inject({}) { |h, (k, v)| h[k.to_s] = v; h }
        answer = Backend.parse_answer(data, scope)

        return nil unless answer.kind_of? Hash
        return answer
      end
    end
  end
end