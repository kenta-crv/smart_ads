self.addEventListener('push', function (event) {
    let data = {};

    if (event.data) {
        try {
            data = event.data.json();
        } catch (e) {
            data = { title: 'Notification', body: event.data.text() };
        }
    }

    const title = data.title || 'Notification';
    const options = {
        body: data.body || '',
        icon: data.icon || '/favicon.ico',
        data: data.url || null
    };

    event.waitUntil(
        self.registration.showNotification(title, options)
    );
});

self.addEventListener('notificationclick', function (event) {
    event.notification.close();
    const url = event.notification.data;

    if (url) {
        event.waitUntil(clients.openWindow(url));
    }
});

