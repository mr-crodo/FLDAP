### Простой способ миграции на Instagram Graph API в Next.js 15 (официальная версия без npm-пакетов)

Instagram Basic Display API полностью устарел с 4 декабря 2024 года — все запросы возвращают ошибки. Официальная рекомендация от Meta (Facebook) — перейти на **Instagram Graph API**, который является частью Facebook Graph API. Это единственный поддерживаемый способ в 2025 году для чтения постов, но с важным ограничением: **работает только для профессиональных аккаунтов (Business или Creator)**, подключённых к Facebook Page. Для личных аккаунтов публичный доступ к постам через API невозможен — Meta закрыла это для приватности. Если профиль `weroomlive` не business/creator, сначала переведи его в такой тип в настройках Instagram (бесплатно, ~5 мин).

Graph API использует стандартный `fetch` (без пакетов вроде axios), OAuth-токены и REST-запросы. Setup займёт ~30–60 мин. Я опишу шаги официально, на основе docs Meta (developers.facebook.com/docs/instagram-api).

#### Шаг 1: Подготовка аккаунта и Facebook App (официальные prerequisites)
1. **Переведи Instagram-аккаунт в Business/Creator**:
    - В Instagram: Профиль → Настройки → Аккаунт → Переключить на профессиональный аккаунт → Business (для бизнеса) или Creator (для инфлюенсеров).
    - Подключи к Facebook Page: В настройках Business-аккаунта → Аккаунты → Поделиться с Facebook → Создай/выбери Page. Это обязательно для Graph API.

2. **Создай Facebook App**:
    - Иди на [developers.facebook.com](https://developers.facebook.com) → My Apps → Create App.
    - Тип: "Business" или "Consumer" (для теста подойдёт Consumer, но для prod — Business).
    - Добавь продукты: Instagram Graph API (и Facebook Login, если нужно OAuth).
    - В Dashboard: Запиши **App ID** и **App Secret** (для генерации токена).
    - Настрой Valid OAuth Redirect URIs: Добавь `https://yourdomain.com/api/auth/callback` (для Next.js — создашь роут позже).

3. **Получи Instagram User ID и Access Token**:
    - Используй [Graph API Explorer](https://developers.facebook.com/tools/explorer):
        - Выбери App, User или Page Token.
        - Permissions: `instagram_basic`, `pages_show_list`, `instagram_manage_insights` (минимум для чтения постов).
        - GET-запрос: `/me/accounts` — получи ID Facebook Page.
        - Затем: `/[page-id]?fields=instagram_business_account` — получи `instagram_business_account.id` (это твой `igUserId` для `weroomlive`).
    - **Генерация токена**:
        - Short-lived (1 час): Через Explorer.
        - Long-lived (60 дней, auto-renew): POST-запрос на `https://graph.facebook.com/oauth/access_token?grant_type=fb_exchange_token&client_id=[APP_ID]&client_secret=[APP_SECRET]&fb_exchange_token=[SHORT_TOKEN]`.
        - Для permanent: Используй Page Access Token (не истекает, если Page активен).
    - Храни токен в `.env.local`: `IG_ACCESS_TOKEN=твой_токен` и `IG_USER_ID=твой_ig_user_id`.

   **Важно**: Токен — секрет! Не коммить в Git. Для prod пройди App Review (Meta проверит app на compliance).

#### Шаг 2: Реализация в Next.js 15 (App Router, без пакетов)
Используй native `fetch` для запросов. Компонент на клиенте (для динамики), но токен лучше тянуть с сервера (API route) для безопасности.

1. **Создай API Route для безопасного fetch (опционально, но рекомендуется)**:
    - Файл `app/api/instagram/posts/route.ts`:
   ```ts
   import { NextRequest, NextResponse } from 'next/server';

   export async function GET(request: NextRequest) {
     const { searchParams } = new URL(request.url);
     const limit = searchParams.get('limit') || '12';

     const token = process.env.IG_ACCESS_TOKEN;
     const igUserId = process.env.IG_USER_ID;

     if (!token || !igUserId) {
       return NextResponse.json({ error: 'Token or ID missing' }, { status: 500 });
     }

     try {
       const response = await fetch(
         `https://graph.instagram.com/${igUserId}/media?fields=id,media_type,media_url,permalink,caption,thumbnail_url&limit=${limit}&access_token=${token}`
       );

       if (!response.ok) {
         throw new Error(`API error: ${response.statusText}`);
       }

       const data = await response.json();
       return NextResponse.json(data.data || []);
     } catch (error) {
       console.error(error);
       return NextResponse.json({ error: 'Failed to fetch posts' }, { status: 500 });
     }
   }
   ```
    - Это серверный endpoint: `/api/instagram/posts?limit=12`. Токен скрыт от клиента.

2. **Компонент для отображения постов** (`components/InstagramPosts.tsx`):
   ```tsx
   'use client';

   import { useState, useEffect } from 'react';

   interface Post {
     id: string;
     media_type: string;
     media_url: string;
     permalink: string;
     caption?: string;
     thumbnail_url?: string;
   }

   export default function InstagramPosts({ limit = 12 }: { limit?: number }) {
     const [posts, setPosts] = useState<Post[]>([]);
     const [loading, setLoading] = useState(true);
     const [error, setError] = useState<string | null>(null);

     useEffect(() => {
       const fetchPosts = async () => {
         try {
           // Если токен на клиенте (для теста): используй fetch напрямую с env (но небезопасно!)
           // Лучше через API route:
           const response = await fetch(`/api/instagram/posts?limit=${limit}`);
           if (!response.ok) throw new Error('API error');
           const data = await response.json();
           setPosts(Array.isArray(data) ? data : []);
         } catch (err) {
           setError('Ошибка загрузки: Проверь business-аккаунт и токен.');
           console.error(err);
         } finally {
           setLoading(false);
         }
       };

       fetchPosts();
     }, [limit]);

     if (loading) return <p>Загрузка постов...</p>;
     if (error) return <p>{error}</p>;
     if (posts.length === 0) return <p>Нет постов. Проверь публичность аккаунта.</p>;

     return (
       <div className="grid grid-cols-3 gap-4 p-4"> {/* Адаптируй под Tailwind или CSS */}
         {posts.map((post) => (
           <a
             key={post.id}
             href={post.permalink}
             target="_blank"
             rel="noopener noreferrer"
             className="block overflow-hidden rounded-lg shadow-md hover:shadow-lg transition-shadow"
           >
             {post.media_type === 'VIDEO' ? (
               <video
                 src={post.media_url}
                 className="w-full h-64 object-cover"
                 controls={false} // Или добавь, если нужно
               />
             ) : (
               <img
                 src={post.media_url}
                 alt={post.caption || 'Instagram post'}
                 className="w-full h-64 object-cover"
               />
             )}
             {post.caption && (
               <p className="mt-2 p-2 text-sm text-gray-600 line-clamp-2">
                 {post.caption}
               </p>
             )}
           </a>
         ))}
       </div>
     );
   }
   ```

3. **Добавь на страницу** (например, `app/page.tsx`):
   ```tsx
   import InstagramPosts from '@/components/InstagramPosts';

   export default function Home() {
     return (
       <main className="container mx-auto py-8">
         <h1 className="text-2xl font-bold mb-4">Instagram посты @weroomlive</h1>
         <InstagramPosts limit={12} />
       </main>
     );
   }
   ```

#### Шаг 3: Тестирование и запуск
- `npm run dev` — открой localhost:3000.
- Проверь консоль: Если ошибка 400/403 — токен неверный или аккаунт не business.
- Rate limits: 200 запросов/час на user (добавь кэш с `useSWR` или localStorage, но без пакетов — простым `sessionStorage`).
- Production: Деплой на Vercel. Env vars: Добавь `IG_ACCESS_TOKEN` и `IG_USER_ID` в настройки проекта. Пройди App Review для публичного app.

#### Почему это официально и просто?
- **Без пакетов**: Только `fetch` и Next.js built-in.
- **Официально**: Полностью по docs Meta — endpoints как `/me/media` (теперь `/[igUserId]/media`), permissions `instagram_basic`.
- **Преимущества Graph API**: Стабильный, больше фич (insights, publishing), permanent tokens для Page.
- **Недостатки**: Только business-аккаунты; setup с Facebook ~30 мин. Для личных — альтернативы: embeds (1 пост) или платные сервисы (Inflact, ~$10/мес).

Если ошибка (например, "Invalid token"), кинь скрин — помогу отдебажить. Для OAuth-flow (если нужно авторизация пользователей) добавь Facebook Login SDK (тоже официально, без npm). Удачи!