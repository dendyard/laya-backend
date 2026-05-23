-- ============================================================
-- Laya Backend — Seed Data
-- Mirrors the current mock data in laya-spa/src/api/content.js
-- ============================================================

USE laya_db;

-- categories
INSERT INTO categories (name, slug) VALUES
  ('Laya Series', 'laya-series')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- articles
INSERT INTO articles (slug, title, subtitle, description, hero_image, card_image, category_id, is_published, sort_order)
VALUES (
  'tato-dayak',
  'Tato Dayak Terakhir',
  'Bagian 1, Mengenal Pak Ding',
  'Serial ini menelusuri jejak tato Dayak sebagai bahasa visual, identitas, dan ingatan kebudayaan.',
  '/assets/tato-dayak1.png',
  '/assets/tato-dayak1.png',
  (SELECT id FROM categories WHERE slug = 'laya-series'),
  1,
  1
)
ON DUPLICATE KEY UPDATE
  title        = VALUES(title),
  subtitle     = VALUES(subtitle),
  description  = VALUES(description),
  hero_image   = VALUES(hero_image),
  card_image   = VALUES(card_image),
  is_published = VALUES(is_published);

-- episode 1
INSERT INTO episodes (article_id, number, title, publish_date, is_published, is_locked)
VALUES (
  (SELECT id FROM articles WHERE slug = 'tato-dayak'),
  1, 'Mengenal Pak Ding', '1 Juni 2026', 1, 0
);

-- episode 2
INSERT INTO episodes (article_id, number, title, publish_date, is_published, is_locked)
VALUES (
  (SELECT id FROM articles WHERE slug = 'tato-dayak'),
  2, 'Membaca Bahasa Visual dalam Tato Dayak', 'Akan Datang', 0, 1
);

-- slides for episode 1
SET @ep1 = (SELECT id FROM episodes WHERE article_id = (SELECT id FROM articles WHERE slug='tato-dayak') AND number = 1);

INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 1, '1931697');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 2, '1931694');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 3, '1931696');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 4, '1931695');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 5, '1931698');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 6, '1931700');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 7, '1931699');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 8, '1931701');
INSERT INTO slides (episode_id, number, video_id) VALUES (@ep1, 9, '1931703');

-- slide 1 contents
SET @s1 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 1);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s1, 'h1', 'Profil Pak Ding', 0),
  (@s1, 'p', 'PERKENALKAN, ia adalah Laurensius Ding Lie. Orang-orang biasa menyapa, Pak Ding.', 1),
  (@s1, 'p', 'Pria 60 tahun itu hidup di sebuah rumah kayu sederhana. Letaknya persis di puncak bukit Ujoh Bilang, Ibu Kota Kabupaten Mahakam Hulu, Kalimantan Timur.', 2),
  (@s1, 'p', 'Berdinding kombinasi kayu ulin dan meranti, beratap seng dilapis plafon, serta berlantai tegel, rumah itu tak dihuni Pak Ding seorang diri. Istri beserta tiga orang anak ikut menemani.', 3),
  (@s1, 'p', 'Dari rumah seluas 10x25 meter persegi yang dikelilingi kebun lalu hutan belantara itu, Pak Ding bergelut dan berjuang, menjaga warisan leluhur: Tato Dayak.', 4);

-- slide 2 contents
SET @s2 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 2);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s2, 'p', '"Selamat datang di Mahakam Ulu," sambut Pak Ding kepada tim Kompas.com, Adhyasta Dirgantara dan Pandawa Borniat.', 0),
  (@s2, 'p', 'Kedua tangannya direntangkan seperti hendak memeluk kami, para tamu jauhnya itu.', 1),
  (@s2, 'p', 'Kami membalas, "Selamat siang Pak."', 2),
  (@s2, 'p', 'Di mata kami, Pak Ding tampak sangat bersahaja. Ia mengenakan celana pendek, kaos hitam, dan topi terbuat dari rotan. Namanya Tapu Wi.', 3),
  (@s2, 'p', '"Ayo nyantai dulu, kita ngopi sambil ngobrol-ngobrol," kata Pak Ding lagi.', 4);

-- slide 3 contents
SET @s3 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 3);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s3, 'p', 'Pak Ding merupakan anak keturunan asli dari Dayak Aoheng.', 0),
  (@s3, 'p', 'Suku Dayak Aoheng sama dengan Suku Dayak Penihing. Mereka termasuk dalam sub-kelompok Dayak Punan.', 1),
  (@s3, 'p', 'Suku Dayak Punan sendiri adalah satu dari enam rumpun utama Suku Dayak yang tinggal di Pulau Borneo.', 2),
  (@s3, 'p', 'Orang-orang Suku Dayak Aoheng awalnya tinggal nomaden di sekitar Pegunungan Muller-Pegunungan Schwaner, Kalimantan Timur, sebelum akhirnya menetap di wilayah Kabupaten Mahakam Hulu. Pak Ding salah satunya.', 3);

-- slide 4 contents
SET @s4 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 4);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s4, 'p', 'Kepada kami, Pak Ding mengaku sudah menekuni tradisi tato Dayak sejak berusia 15 tahun.', 0),
  (@s4, 'p', 'Kala itu, Ding remaja ingin mendalami lebih jauh makna tato Dayak warisan leluhurnya.', 1),
  (@s4, 'p', 'Keinginan itu menuntunnya berguru ke kakeknya sendiri bernama Paron.', 2),
  (@s4, 'p', '"Beliaulah yang selalu mengajari saya teknik menato dan desain tato sesuai dengan etnis dan kasta," ujar Pak Ding.', 3);

-- slide 5 contents
SET @s5 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 5);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s5, 'p', 'Pak Ding melanjutkan, hal pertama yang diajarkan Paron kepadanya adalah makna tato bagi Suku Dayak.', 0),
  (@s5, 'p', 'Para leluhur dan keturunannya kini percaya ketika mereka tiada, akan memasuki sebuah lorong gelap gulita.', 1),
  (@s5, 'p', 'Tato yang dirajah di sekujur tubuh akan mengeluarkan cahaya dan menuntun mereka berjalan ke ujung lorong, surga.', 2),
  (@s5, 'p', '"Itulah yang terus kakek saya katakan dan saya teruskan kepada siapapun," ujar Pak Ding.', 3);

-- slide 6 contents
SET @s6 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 6);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s6, 'p', 'Meski bermuara pada satu filosofi, setiap tato Suku Dayak Penihing memiliki motif yang berbeda-beda beserta artinya masing-masing.', 0),
  (@s6, 'p', 'Motif binatang biasanya direpresentasikan dengan bentuk naga, burung enggang, harimau, dan anjing.', 1),
  (@s6, 'p', 'Motif naga melambangkan kekuatan, kebijaksanaan, dan perlindungan. Motif burung enggang (rangkong) melambangkan keindahan, kedamaian, dan keharmonisan dengan alam.', 2);

-- slide 7 contents
SET @s7 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 7);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s7, 'p', 'Untuk motif tumbuhan, direpresentasikan dengan bentuk bunga terong yang melambangkan kedewasaan, kemampuan beradaptasi, dan merepresentasikan kekayaan alam Kalimantan.', 0),
  (@s7, 'p', '"Tato ini menunjukkan status di suku dan kedewasaan. Artinya, saya sudah siap mengabdi kepada keluarga sekaligus berbuat kebaikan untuk masyarakat," ujar Pak Ding.', 1),
  (@s7, 'p', 'Penempatan tato di leher depan pun memiliki arti khusus. Hanya orang dengan kasta tinggi dan keturunan kerajaan pada Suku Dayak Aoheng saja yang boleh ditato pada bagian leher.', 2);

-- slide 8 contents
SET @s8 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 8);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s8, 'p', 'Tidak hanya itu, ada pula tato motif manusia dalam pose dan mengenakan atribut tertentu. Biasanya gaya motif tato bukan realis, melainkan abstrak.', 0),
  (@s8, 'p', 'Tato motif ini melambangkan status sosial atau pengalaman hidup tertentu yang pernah dialami.', 1),
  (@s8, 'p', 'Beberapa motif manusia juga dijadikan kenangan akan figur nenek moyang atau tokoh penting dalam Suku Dayak.', 2);

-- slide 9 contents
SET @s9 = (SELECT id FROM slides WHERE episode_id = @ep1 AND number = 9);
INSERT INTO slide_contents (slide_id, type, content, order_index) VALUES
  (@s9, 'p', 'Tato Dayak bukan sekadar ornamen tubuh — ia adalah arsip hidup yang mencatat perjalanan, status, dan hubungan seseorang dengan alam semesta.', 0),
  (@s9, 'p', 'Pak Ding berharap generasi muda Dayak Aoheng tetap mengenal dan menghargai tradisi ini.', 1),
  (@s9, 'p', '"Kalau tidak ada yang meneruskan, siapa yang akan menjaga warisan leluhur kita?" kata Pak Ding.', 2);

-- default settings
INSERT INTO settings (`key`, value) VALUES
  ('app_name', 'Laya'),
  ('app_version', '1.0.0'),
  ('premium_price_monthly', '69000'),
  ('premium_price_yearly', '599000'),
  ('premium_currency', 'IDR'),
  ('maintenance_mode', '0')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- default admin user  (password: admin123)
INSERT INTO users (name, email, password, role, is_premium) VALUES
  ('Admin Laya', 'admin@laya.id', '$2y$10$Autki4OY2cCpWBpFxkGWy.OrswrZUy10tujdg4On/cWJtDQuIPBvS', 'admin', 1)
ON DUPLICATE KEY UPDATE name = VALUES(name);
