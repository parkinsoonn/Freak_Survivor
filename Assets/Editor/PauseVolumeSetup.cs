using System.IO;
using UnityEditor;
using UnityEditor.Events;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

// Geçici kurulum: Game sahnesinde PauseVolumeIcon yoksa derlemeden sonra bir kez çalışır.
// ESC menüsüne ana menünün ses slider'ını kopyalar ve goblin düşmanını ekler.
[InitializeOnLoad]
public static class PauseVolumeSetup
{
    const string GameScenePath = "Assets/Scenes/Game.unity";
    const string MainMenuPath = "Assets/Scenes/MainMenu.unity";
    const string GoblinSpritePath = "Assets/Sprites/goblin.png";
    const string GoblinPrefabPath = "Assets/Prefabs/goblin.prefab";
    const float CanvasScale = 1.8f; // Ana menü canvas'ı 800x600, oyun canvas'ı 1920x1080

    static PauseVolumeSetup()
    {
        EditorApplication.delayCall += () =>
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode) return;
            if (File.ReadAllText(GameScenePath).Contains("PauseVolumeIcon")) return;
            Run();
        };
    }

    [MenuItem("Tools/Freak Survivor/ESC Ses ve Goblin Kurulumu")]
    static void Run()
    {
        if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

        GameObject goblin = CreateGoblinPrefab();

        Scene game = EditorSceneManager.OpenScene(GameScenePath, OpenSceneMode.Single);
        GameManager gm = Object.FindAnyObjectByType<GameManager>();

        AddGoblinToSpawner(goblin);
        CopyMenuVolumeSlider(gm);

        EditorSceneManager.MarkSceneDirty(game);
        EditorSceneManager.SaveScene(game);
        Debug.Log("[Setup] ESC ses slider'ı ve goblin kuruldu.");
    }

    static GameObject CreateGoblinPrefab()
    {
        TextureImporter importer = (TextureImporter)AssetImporter.GetAtPath(GoblinSpritePath);
        importer.textureType = TextureImporterType.Sprite;
        importer.spriteImportMode = SpriteImportMode.Single;
        importer.filterMode = FilterMode.Point;
        importer.textureCompression = TextureImporterCompression.Uncompressed;
        importer.spritePixelsPerUnit = 32f; // Diğer düşman görselleriyle aynı
        importer.SaveAndReimport();

        GameObject root = PrefabUtility.LoadPrefabContents("Assets/Prefabs/mumyavari.prefab");
        root.name = "goblin";
        root.GetComponent<SpriteRenderer>().sprite = AssetDatabase.LoadAssetAtPath<Sprite>(GoblinSpritePath);
        EnemyController enemy = root.GetComponent<EnemyController>();
        enemy.speed = 3.3f;
        enemy.health = 2;
        GameObject prefab = PrefabUtility.SaveAsPrefabAsset(root, GoblinPrefabPath);
        PrefabUtility.UnloadPrefabContents(root);
        return prefab;
    }

    static void AddGoblinToSpawner(GameObject goblin)
    {
        EnemySpawner spawner = Object.FindAnyObjectByType<EnemySpawner>();
        if (System.Array.IndexOf(spawner.enemyPrefabs, goblin) >= 0) return;

        GameObject[] prefabs = new GameObject[spawner.enemyPrefabs.Length + 1];
        spawner.enemyPrefabs.CopyTo(prefabs, 0);
        prefabs[prefabs.Length - 1] = goblin;
        spawner.enemyPrefabs = prefabs;
        EditorUtility.SetDirty(spawner);
    }

    static void CopyMenuVolumeSlider(GameManager gm)
    {
        Transform panel = gm.pausePanel.transform;

        // Önceki varsayılan slider ve yazıyı kaldır
        foreach (string name in new[] { "PauseVolumeSlider", "PauseVolumeLabel", "PauseVolumeIcon" })
        {
            Transform old = panel.Find(name);
            if (old != null) Object.DestroyImmediate(old.gameObject);
        }

        // Ana menü sahnesi sadece kopyalamak için açılır, kaydedilmeden kapatılır
        Scene menu = EditorSceneManager.OpenScene(MainMenuPath, OpenSceneMode.Additive);
        Slider menuSlider = null;
        RawImage menuSpeaker = null;
        foreach (GameObject root in menu.GetRootGameObjects())
        {
            if (menuSlider == null) menuSlider = root.GetComponentInChildren<Slider>(true);
            foreach (RawImage raw in root.GetComponentsInChildren<RawImage>(true))
            {
                if (raw.texture != null && raw.texture.name == "hoparlor") menuSpeaker = raw;
            }
        }

        GameObject sliderObject = Object.Instantiate(menuSlider.gameObject, panel, false);
        sliderObject.name = "PauseVolumeSlider";
        RectTransform sliderRect = sliderObject.GetComponent<RectTransform>();
        sliderRect.anchorMin = sliderRect.anchorMax = sliderRect.pivot = new Vector2(0.5f, 0.5f);
        sliderRect.localScale = Vector3.one * CanvasScale; // Tutamaç dahil her şey orantılı büyüsün
        sliderRect.anchoredPosition = new Vector2(40f, -360f);
        float sliderWidth = sliderRect.sizeDelta.x * CanvasScale;

        Slider slider = sliderObject.GetComponent<Slider>();
        for (int i = slider.onValueChanged.GetPersistentEventCount() - 1; i >= 0; i--)
        {
            UnityEventTools.RemovePersistentListener(slider.onValueChanged, i);
        }
        UnityEventTools.AddPersistentListener(slider.onValueChanged, gm.SetVolume);

        if (menuSpeaker != null)
        {
            GameObject icon = Object.Instantiate(menuSpeaker.gameObject, panel, false);
            icon.name = "PauseVolumeIcon";
            foreach (Button button in icon.GetComponents<Button>()) Object.DestroyImmediate(button);
            RectTransform iconRect = icon.GetComponent<RectTransform>();
            iconRect.anchorMin = iconRect.anchorMax = iconRect.pivot = new Vector2(0.5f, 0.5f);
            iconRect.localScale = Vector3.one * CanvasScale;
            float iconWidth = iconRect.sizeDelta.x * CanvasScale;
            iconRect.anchoredPosition = new Vector2(40f - sliderWidth / 2f - iconWidth / 2f - 20f, -360f);
        }
        else
        {
            // Hoparlör bulunamazsa yine de tekrar çalışmaması için boş işaret nesnesi
            new GameObject("PauseVolumeIcon", typeof(RectTransform)).transform.SetParent(panel, false);
        }

        EditorSceneManager.CloseScene(menu, true);

        gm.volumeSlider = slider;
        EditorUtility.SetDirty(gm);
    }
}
