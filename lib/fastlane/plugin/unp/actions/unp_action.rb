require 'fastlane/action'
require_relative '../helper/unp_helper'
require 'faraday'
require 'faraday_middleware'

module Fastlane
  module Actions
    class UnpAction < Action
      def self.run(params)
        UI.message("The unp plugin is working!")
        api_host = 'https://www.pgyer.com/apiv2/app/upload'
        api_key = params[:api_key]

        build_file = [
          params[:ipa]
        ].detect { |e| !e.to_s.empty? }

        if build_file.nil?
          UI.user_error!("没有找到需要上传的包")
        end
        UI.message("即将上传 #{build_file}")

        # 上传描述信息
        update_description = params[:update_description]
        if update_description.nil?
          update_description = ''
        end
        install_type = params[:install_type]
        if install_type.nil?
          install_type = '1'
        end

        install_date = params[:install_date]
        if install_date.nil?
          install_date = '2'
        end
        # 开始上传
        conn_options = {
          request: {
            timeout: 1000,
            open_timeout: 300
          }
        }

        pgyer_client = Faraday.new(nil, conn_options) do |c|
          c.request(:multipart)
          c.request(:url_encoded)
          c.response(:json, content_type: /\bjson$/)
          c.adapter(:net_http)
        end

        params = {
          '_api_key' => api_key,
          'file' => Faraday::UploadIO.new(build_file, 'application/octet-stream'),
          'buildInstallType' => install_type,
          'buildInstallDate' => install_date,
          'buildUpdateDescription' => update_description
        }
        UI.message("开始上传#{build_file}到蒲公英")
        response = pgyer_client.post api_host, params
        info = response.body

        if info['code'] != 0
          UI.user_error!("上传失败#{info['message']}")
        end
        UI.success("上传成功#{info['data']['buildShortcutUrl']}")

      end

      def self.description
        "应用上传到蒲公英, 详情查看 https://www.pgyer.com"
      end

      def self.authors
        ["Xu Zhen"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "将beta 版版本的应用上传到蒲公英，发布测试"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_key,
                                  env_name: "UNP_AIP_KEY",
                               description: "你到蒲公英账号 api key",
                                  optional: false,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: "UNP_IPA",
                                       description: "你所生成的IPA文件的路径。你可以使用环境变量来只想 UNP_IPA",
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("找不到.ipa文件'#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :update_description,
                                       env_name: "UNP_UPDATE_DESCRIPTION",
                                       description: "设置你app的描述信息",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :install_type,
                                       env_name: "UNP_INSTALL_TYPE",
                                       description: "设置你安装app的类型，值为(1,2,3，默认为1 公开安装)",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :install_date,
                                       env_name: "UNP_INSTALL_DATE",
                                       description: "设置安装有效期，值为：1 设置有效时间， 2 长期有效，如果不填写不修改上一次的设置",
                                       optional: true,
                                       type: String)
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
