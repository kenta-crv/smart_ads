class EmbedController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_user_by_api_key
  before_action :set_cors_headers
  after_action :set_cors_headers

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type'
  end

  def show
    render js: embed_script, content_type: 'application/javascript'
  end

  def register
    if request.method == 'OPTIONS'
      head :ok
      return
    end
    
    subscription_data = JSON.parse(request.body.read)
    
    if @user
      push_subscription = @user.push_subscriptions.find_or_initialize_by(
        endpoint: subscription_data['endpoint']
      )

      push_subscription.assign_attributes(
        keys: subscription_data['keys'],
        browser: detect_browser,
        status: 'active'
      )

      if push_subscription.save
        render json: { success: true, id: push_subscription.id }, status: :created
      else
        render json: { success: false, error: push_subscription.errors.full_messages.to_sentence }, status: :unprocessable_content
      end
    else
      render json: { success: false, error: 'Invalid API key' }, status: :unauthorized
    end
  end

  private

  def set_user_by_api_key
    @user = User.find_by(api_key: params[:api_key])
  end

  def detect_browser
    user_agent = request.user_agent.to_s.downcase
    if user_agent.include?('chrome')
      'Chrome'
    elsif user_agent.include?('firefox')
      'Firefox'
    elsif user_agent.include?('safari')
      'Safari'
    else
      'Unknown'
    end
  end

  def embed_script
    vapid_public_key = Rails.application.credentials.dig(:vapid, :public_key) || ENV['VAPID_PUBLIC_KEY']

    <<~JAVASCRIPT
      (function() {
        'use strict';
        
        var API_KEY = '#{params[:api_key]}';
        var API_URL = '#{request.base_url}';
        var VAPID_PUBLIC_KEY = '#{vapid_public_key}';
        var wasExistingSubscription = false;
        
        if (!('Notification' in window)) {
          return;
        }
        
        if (!('serviceWorker' in navigator)) {
          return;
        }
        
        if (!('PushManager' in window)) {
          return;
        }

        if (!VAPID_PUBLIC_KEY) {
          return;
        }
        
        function requestPermission() {
          if (Notification.permission === 'default') {
            Notification.requestPermission().then(function(permission) {
              if (permission === 'granted') {
                registerServiceWorker();
              } else {
              }
            });
          } else if (Notification.permission === 'granted') {
            registerServiceWorker();
          }
        }
        
        function registerServiceWorker() {
          if (window.location.protocol === 'file:') {
            return;
          }
          
          navigator.serviceWorker.register('/service-worker.js')
            .then(function(registration) {
              return registration.pushManager.getSubscription().then(function(existingSubscription) {
                if (existingSubscription) {
                  wasExistingSubscription = true;
                  return existingSubscription;
                }
                
                return registration.pushManager.subscribe({
                  userVisibleOnly: true,
                  applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY)
                });
              });
            })
            .then(function(subscription) {
              sendSubscriptionToServer(subscription, wasExistingSubscription);
            })
            .catch(function(error) {
            });
        }
        
        function sendSubscriptionToServer(subscription, alreadyRegistered) {
          if (alreadyRegistered === undefined) {
            alreadyRegistered = false;
          }
          
          fetch(API_URL + '/embed/register?api_key=' + API_KEY, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              endpoint: subscription.endpoint,
              keys: {
                p256dh: arrayBufferToBase64(subscription.getKey('p256dh')),
                auth: arrayBufferToBase64(subscription.getKey('auth'))
              }
            })
          })
          .then(function(response) {
            return response.json();
          })
          .then(function(data) {
            if (data.success) {
              if (!alreadyRegistered) {
                showNotificationModal('success', '通知の許可が完了しました！');
              }
            } else {
            }
          })
          .catch(function(error) {
          });
        }
        
        function urlBase64ToUint8Array(base64String) {
          var padding = '='.repeat((4 - base64String.length % 4) % 4);
          var base64 = (base64String + padding)
            .replace(/\\-/g, '+')
            .replace(/_/g, '/');
          
          var rawData = window.atob(base64);
          var outputArray = new Uint8Array(rawData.length);
          
          for (var i = 0; i < rawData.length; ++i) {
            outputArray[i] = rawData.charCodeAt(i);
          }
          return outputArray;
        }
        
        function arrayBufferToBase64(buffer) {
          var binary = '';
          var bytes = new Uint8Array(buffer);
          var len = bytes.byteLength;
          for (var i = 0; i < len; i++) {
            binary += String.fromCharCode(bytes[i]);
          }
          return window.btoa(binary);
        }
        
        function showNotificationModal(type, message) {
          var modal = document.createElement('div');
          modal.style.cssText = 'position:fixed;top:20px;right:20px;background:#4CAF50;color:white;padding:15px 20px;border-radius:5px;z-index:10000;box-shadow:0 4px 6px rgba(0,0,0,0.1);';
          modal.textContent = message;
          document.body.appendChild(modal);
          
          setTimeout(function() {
            modal.style.opacity = '0';
            modal.style.transition = 'opacity 0.3s';
            setTimeout(function() {
              document.body.removeChild(modal);
            }, 300);
          }, 3000);
        }
        
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', requestPermission);
        } else {
          requestPermission();
        }
      })();
    JAVASCRIPT
  end
end

