module DeferredEnv
  ALLOWED_USERS = ['danmayer']

  API_KEY = ENV['SERVER_RESPONDER_API_KEY']
  MAIL_API_KEY = ENV['MAILGUN_API_KEY']
  MAIL_API_URL = "https://api:#{MAIL_API_KEY}@api.mailgun.net/v2/app7941314.mailgun.org"

  #trusted IPs from GH /admin/hooks
  #https://github.com/danmayer/deferred-server/settings/hooks
  TRUSTED_IPS   = ['207.97.227.253', '50.57.128.197',
                   '108.171.174.178', '127.0.0.1',
                   '50.57.231.61', '54.235.183.49',
                   '54.235.183.23', '54.235.118.251',
                   '54.235.120.57', '54.235.120.61',
                   '54.235.120.62']

end
