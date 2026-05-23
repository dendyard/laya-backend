-- ============================================================
-- Laya Backend — PostgreSQL Seed Data
-- ============================================================

\connect laya_db

-- categories
INSERT INTO categories (name, slug) VALUES ('Laya Series', 'laya-series')
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name;

-- series
INSERT INTO series (slug, title, subtitle, description, hero_image, card_image, category_id, is_published, sort_order)
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
ON CONFLICT (slug) DO UPDATE SET
  title        = EXCLUDED.title,
  subtitle     = EXCLUDED.subtitle,
  description  = EXCLUDED.description,
  hero_image   = EXCLUDED.hero_image,
  card_image   = EXCLUDED.card_image,
  is_published = EXCLUDED.is_published;

DO $$
DECLARE
  v_series_id INTEGER;
  v_ep1        INTEGER;
BEGIN
  SELECT id INTO v_series_id FROM series WHERE slug = 'tato-dayak';

  INSERT INTO episodes (series_id, number, title, publish_date, is_published, is_locked)
  VALUES (v_series_id, 1, 'Mengenal Pak Ding', '1 Juni 2026', 1, 0)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_ep1;

  IF v_ep1 IS NULL THEN
    SELECT id INTO v_ep1 FROM episodes WHERE series_id = v_series_id AND number = 1;
  END IF;

  INSERT INTO episodes (series_id, number, title, publish_date, is_published, is_locked)
  VALUES (v_series_id, 2, 'Membaca Bahasa Visual dalam Tato Dayak', 'Akan Datang', 0, 1)
  ON CONFLICT DO NOTHING;

  -- slides with HTML content
  INSERT INTO slides (episode_id, number, video_id, content) VALUES
  (v_ep1, 1, '1931697',
   '<h1>Profil Pak Ding</h1><p>PERKENALKAN, ia adalah Laurensius Ding Lie. Orang-orang biasa menyapa, Pak Ding.</p><p>Pria 60 tahun itu hidup di sebuah rumah kayu sederhana. Letaknya persis di puncak bukit Ujoh Bilang, Ibu Kota Kabupaten Mahakam Hulu, Kalimantan Timur.</p><p>Berdinding kombinasi kayu ulin dan meranti, beratap seng dilapis plafon, serta berlantai tegel, rumah itu tak dihuni Pak Ding seorang diri. Istri beserta tiga orang anak ikut menemani.</p><p>Dari rumah seluas 10x25 meter persegi yang dikelilingi kebun lalu hutan belantara itu, Pak Ding bergelut dan berjuang, menjaga warisan leluhur: Tato Dayak.</p>'),
  (v_ep1, 2, '1931694',
   '<p>"Selamat datang di Mahakam Ulu," sambut Pak Ding kepada tim Kompas.com, Adhyasta Dirgantara dan Pandawa Borniat.</p><p>Kedua tangannya direntangkan seperti hendak memeluk kami, para tamu jauhnya itu.</p><p>Kami membalas, "Selamat siang Pak."</p><p>Di mata kami, Pak Ding tampak sangat bersahaja. Ia mengenakan celana pendek, kaos hitam, dan topi terbuat dari rotan. Namanya Tapu Wi.</p><p>"Ayo nyantai dulu, kita ngopi sambil ngobrol-ngobrol," kata Pak Ding lagi.</p>'),
  (v_ep1, 3, '1931696',
   '<p>Pak Ding merupakan anak keturunan asli dari Dayak Aoheng.</p><p>Suku Dayak Aoheng sama dengan Suku Dayak Penihing. Mereka termasuk dalam sub-kelompok Dayak Punan.</p><p>Suku Dayak Punan sendiri adalah satu dari enam rumpun utama Suku Dayak yang tinggal di Pulau Borneo.</p><p>Orang-orang Suku Dayak Aoheng awalnya tinggal nomaden di sekitar Pegunungan Muller-Pegunungan Schwaner, Kalimantan Timur, sebelum akhirnya menetap di wilayah Kabupaten Mahakam Hulu. Pak Ding salah satunya.</p>'),
  (v_ep1, 4, '1931695',
   '<p>Kepada kami, Pak Ding mengaku sudah menekuni tradisi tato Dayak sejak berusia 15 tahun.</p><p>Kala itu, Ding remaja ingin mendalami lebih jauh makna tato Dayak warisan leluhurnya.</p><p>Keinginan itu menuntunnya berguru ke kakeknya sendiri bernama Paron.</p><p>"Beliaulah yang selalu mengajari saya teknik menato dan desain tato sesuai dengan etnis dan kasta," ujar Pak Ding.</p>'),
  (v_ep1, 5, '1931698',
   '<p>Pak Ding melanjutkan, hal pertama yang diajarkan Paron kepadanya adalah makna tato bagi Suku Dayak.</p><p>Para leluhur dan keturunannya kini percaya ketika mereka tiada, akan memasuki sebuah lorong gelap gulita.</p><p>Tato yang dirajah di sekujur tubuh akan mengeluarkan cahaya dan menuntun mereka berjalan ke ujung lorong, surga.</p><p>"Itulah yang terus kakek saya katakan dan saya teruskan kepada siapapun," ujar Pak Ding.</p>'),
  (v_ep1, 6, '1931700',
   '<p>Meski bermuara pada satu filosofi, setiap tato Suku Dayak Penihing memiliki motif yang berbeda-beda beserta artinya masing-masing.</p><p>Motif binatang biasanya direpresentasikan dengan bentuk naga, burung enggang, harimau, dan anjing.</p><p>Motif naga melambangkan kekuatan, kebijaksanaan, dan perlindungan. Motif burung enggang (rangkong) melambangkan keindahan, kedamaian, dan keharmonisan dengan alam.</p>'),
  (v_ep1, 7, '1931699',
   '<p>Untuk motif tumbuhan, direpresentasikan dengan bentuk bunga terong yang melambangkan kedewasaan, kemampuan beradaptasi, dan merepresentasikan kekayaan alam Kalimantan.</p><p>"Tato ini menunjukkan status di suku dan kedewasaan. Artinya, saya sudah siap mengabdi kepada keluarga sekaligus berbuat kebaikan untuk masyarakat," ujar Pak Ding.</p><p>Penempatan tato di leher depan pun memiliki arti khusus. Hanya orang dengan kasta tinggi dan keturunan kerajaan pada Suku Dayak Aoheng saja yang boleh ditato pada bagian leher.</p>'),
  (v_ep1, 8, '1931701',
   '<p>Tidak hanya itu, ada pula tato motif manusia dalam pose dan mengenakan atribut tertentu. Biasanya gaya motif tato bukan realis, melainkan abstrak.</p><p>Tato motif ini melambangkan status sosial atau pengalaman hidup tertentu yang pernah dialami.</p><p>Beberapa motif manusia juga dijadikan kenangan akan figur nenek moyang atau tokoh penting dalam Suku Dayak.</p>'),
  (v_ep1, 9, '1931703',
   '<p>Tato Dayak bukan sekadar ornamen tubuh — ia adalah arsip hidup yang mencatat perjalanan, status, dan hubungan seseorang dengan alam semesta.</p><p>Pak Ding berharap generasi muda Dayak Aoheng tetap mengenal dan menghargai tradisi ini.</p><p>"Kalau tidak ada yang meneruskan, siapa yang akan menjaga warisan leluhur kita?" kata Pak Ding.</p>');

END $$;

-- default settings
INSERT INTO settings (key, value) VALUES
  ('app_name',              'Laya'),
  ('app_version',           '1.0.0'),
  ('premium_price_monthly', '69000'),
  ('premium_price_yearly',  '599000'),
  ('premium_currency',      'IDR'),
  ('maintenance_mode',      '0')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- admin user  (password: admin123)
INSERT INTO users (name, email, password, role, is_premium) VALUES
  ('Admin Laya', 'admin@laya.id', '$2y$10$Autki4OY2cCpWBpFxkGWy.OrswrZUy10tujdg4On/cWJtDQuIPBvS', 'admin', 1)
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;
