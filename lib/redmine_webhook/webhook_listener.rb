# encoding: utf-8
module RedmineWebhook
  class WebhookListener < Redmine::Hook::Listener

    def controller_issues_new_after_save(context = {})
      issue = context[:issue]
      controller = context[:controller]
      project = issue.project
      webhook = Webhook.where(:project_id => project.project.id).first
      return unless webhook
      post(webhook, issue_to_json(issue, controller))
    end

    def controller_issues_edit_after_save(context = {})
      journal = context[:journal]
      controller = context[:controller]
      issue = context[:issue]
      project = issue.project
      webhook = Webhook.where(:project_id => project.project.id).first
      return unless webhook
      post(webhook, journal_to_json(issue, journal, controller))
    end

    private
    def issue_to_json(issue, controller)
      {
        :payload => {
          :action => 'opened',
          :issue => RedmineWebhook::IssueWrapper.new(issue).to_hash,
          :url => controller.issue_url(issue)
        }
      }.to_json
    end

    def journal_to_json(issue, journal, controller)
      {
        :payload => {
          :action => 'updated',
          :issue => RedmineWebhook::IssueWrapper.new(issue).to_hash,
          :journal => RedmineWebhook::JournalWrapper.new(journal).to_hash,
          :url => controller.issue_url(issue)
        }
      }.to_json
    end

    def post(webhook, request_body)
      Thread.start do
        begin
        

      jandiapi(webhook.url,JSON.parse(request_body))
        rescue => e
          Rails.logger.error e
        end
      end
    end
def jandiapi(_endpoint,m)
    
    project=m["payload"]["issue"]["project"]["name"]
    action=m["payload"]["action"]
    subject=m["payload"]["issue"]["subject"]
    desc=m["payload"]["issue"]["description"]
    author=(m["payload"]["issue"]["author"].nil?) ? "": m["payload"]["issue"]["author"]["login"]
    assignee=(m["payload"]["issue"]["assignee"].nil?) ? "not assign": m["payload"]["issue"]["assignee"]["login"]
    status=m["payload"]["issue"]["status"]["name"]
    url=m["payload"]["url"]
      @msgbody = {
        body: "Redmine - #{project}", #Body text (Required)
        connectColor: '#FAC11B', #Hex code color of attachment bar
    connectInfo: [{
        title: "#{subject}" , #1st attachment area title
        description: "#{desc}" #1st attachment description
        },
        {
        title: 'assigner', #2nd attachment area title
        description: "#{assignee}", #2nd attachment description        
        },
        {
        title: "#{status}", #2nd attachment area title
        imageUrl: "#{url}" #2nd attachment description        
        }]
      }.to_json
      uri = URI(_endpoint)
      http = Net::HTTP.new(uri.host, 443)
      request = Net::HTTP::Post.new(uri.request_uri,initheader = {'Content-Type' =>'application/json','Accept' =>'application/vnd.tosslab.jandi-v2+json'})
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request.body = "#{@msgbody}"
      res = http.request(request)
      puts res.body     

  end
 
 end
end