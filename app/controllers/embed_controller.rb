class EmbedController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_user_by_api_key

  def show
    render js: embed_script, content_type: 'application/javascript'
  end

  def register
    subscription_data = JSON.parse(request.body.read)
    
    if @user
      push_subscription = @user.push_subscriptions.create!(
        endpoint: subscription_data['endpoint'],
        keys: subscription_data['keys'],
        browser: detect_browser,
        status: 'active'
      )
      
      render json: { success: true, id: push_subscription.id }, status: :created
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
    <<~JAVASCRIPT
      (function() {
        'use strict';
        
        var API_KEY = '#{params[:api_key]}';
        var API_URL = '#{request.base_url}';
        
        if (!('Notification' in window) || !('serviceWorker' in navigator) || !('PushManager' in window)) {
          console.warn('This browser does not support push notifications');
          return;
        }
        
        function requestPermission() {
          if (Notification.permission === 'default') {
            Notification.requestPermission().then(function(permission) {
              if (permission === 'granted') {
                registerServiceWorker();
              } else {
                console.log('Notification permission denied');
              }
            });
          } else if (Notification.permission === 'granted') {
            registerServiceWorker();
          }
        }
        
        function registerServiceWorker() {
          navigator.serviceWorker.register('/service-worker.js')
            .then(function(registration) {
              return registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: urlBase64ToUint8Array('#{@user&.api_key || 'public_key_placeholder'}')
              });
            })
            .then(function(subscription) {
              sendSubscriptionToServer(subscription);
            })
            .catch(function(error) {
              console.error('Service Worker registration failed:', error);
            });
        }
        
        function sendSubscriptionToServer(subscription) {
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
              console.log('Push subscription registered successfully');
              showNotificationModal('success', '通知の許可が完了しました！');
            } else {
              console.error('Failed to register subscription:', data.error);
            }
          })
          .catch(function(error) {
            console.error('Error registering subscription:', error);
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

