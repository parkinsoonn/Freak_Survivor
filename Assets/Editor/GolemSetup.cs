using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

// Geçici kurulum: golem prefab'ı yoksa derlemeden sonra bir kez çalışır.
// Nişangah imlecini ve golem mini-boss'u (yürüme animasyonu + prefab) kurar, Game sahnesine bağlar.
[InitializeOnLoad]
public static class GolemSetup
{
    const string GameScenePath = "Assets/Scenes/Game.unity";
    const string CursorPath = "Assets/Sprites/nisangah.png";
    const string GolemSheetPath = "Assets/Sprites/golem_walk.png";
    const string GolemPrefabPath = "Assets/Prefabs/golem.prefab";
    const string AnimFolder = "Assets/Animations";
    const int FrameCount = 4;
    const float FrameTime = 0.15f; // Aseprite'taki kare süresiyle aynı

    static GolemSetup()
    {
        EditorApplication.delayCall += () =>
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode) return;
            if (File.Exists(GolemPrefabPath)) return;
            Run();
        };
    }

    [MenuItem("Tools/Freak Survivor/Nişangah ve Golem Kurulumu")]
    static void Run()
    {
        if (!EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo()) return;

        Texture2D cursor = ImportCursor();
        GameObject golem = CreateGolemPrefab(CreateWalkController());

        Scene game = EditorSceneManager.OpenScene(GameScenePath, OpenSceneMode.Single);

        GameManager gm = Object.FindAnyObjectByType<GameManager>();
        gm.crosshairCursor = cursor;
        EditorUtility.SetDirty(gm);

        EnemySpawner spawner = Object.FindAnyObjectByType<EnemySpawner>();
        spawner.miniBossPrefab = golem;
        EditorUtility.SetDirty(spawner);

        EditorSceneManager.MarkSceneDirty(game);
        EditorSceneManager.SaveScene(game);
        Debug.Log("[Setup] Nişangah imleci ve golem mini-boss kuruldu.");
    }

    static Texture2D ImportCursor()
    {
        TextureImporter importer = (TextureImporter)AssetImporter.GetAtPath(CursorPath);
        importer.textureType = TextureImporterType.Cursor;
        importer.filterMode = FilterMode.Point;
        importer.textureCompression = TextureImporterCompression.Uncompressed;
        importer.mipmapEnabled = false;
        importer.SaveAndReimport();
        return AssetDatabase.LoadAssetAtPath<Texture2D>(CursorPath);
    }

    static AnimatorController CreateWalkController()
    {
        TextureImporter importer = (TextureImporter)AssetImporter.GetAtPath(GolemSheetPath);
        importer.textureType = TextureImporterType.Sprite;
        importer.spriteImportMode = SpriteImportMode.Multiple;
        importer.filterMode = FilterMode.Point;
        importer.textureCompression = TextureImporterCompression.Uncompressed;
        importer.spritePixelsPerUnit = 32f; // Diğer düşman görselleriyle aynı
        importer.mipmapEnabled = false;
#pragma warning disable 618 // spritesheet eski ama hâlâ çalışan dilimleme API'si
        SpriteMetaData[] frames = new SpriteMetaData[FrameCount];
        for (int i = 0; i < FrameCount; i++)
        {
            frames[i] = new SpriteMetaData
            {
                name = "golem_walk_" + i,
                rect = new Rect(i * 32, 0, 32, 32),
                alignment = (int)SpriteAlignment.Center,
                pivot = new Vector2(0.5f, 0.5f)
            };
        }
        importer.spritesheet = frames;
#pragma warning restore 618
        importer.SaveAndReimport();

        Sprite[] sprites = AssetDatabase.LoadAllAssetsAtPath(GolemSheetPath).OfType<Sprite>().OrderBy(s => s.name).ToArray();

        // Son kare ilk sprite'ı tekrarlar ki 4. kare de tam süre görünsün
        ObjectReferenceKeyframe[] keys = new ObjectReferenceKeyframe[sprites.Length + 1];
        for (int i = 0; i <= sprites.Length; i++)
        {
            keys[i] = new ObjectReferenceKeyframe { time = i * FrameTime, value = sprites[i % sprites.Length] };
        }

        AnimationClip clip = new AnimationClip { frameRate = 12 };
        AnimationUtility.SetObjectReferenceCurve(clip, EditorCurveBinding.PPtrCurve("", typeof(SpriteRenderer), "m_Sprite"), keys);
        AnimationClipSettings settings = AnimationUtility.GetAnimationClipSettings(clip);
        settings.loopTime = true;
        AnimationUtility.SetAnimationClipSettings(clip, settings);

        if (!AssetDatabase.IsValidFolder(AnimFolder)) AssetDatabase.CreateFolder("Assets", "Animations");
        AssetDatabase.CreateAsset(clip, AnimFolder + "/golem_walk.anim");
        return AnimatorController.CreateAnimatorControllerAtPathWithClip(AnimFolder + "/golem.controller", clip);
    }

    static GameObject CreateGolemPrefab(AnimatorController controller)
    {
        GameObject root = PrefabUtility.LoadPrefabContents("Assets/Prefabs/goblin.prefab");
        root.name = "golem";
        root.transform.localPosition = Vector3.zero;
        root.transform.localScale = Vector3.one * 1.6f; // Normal düşmanların ~2 katı

        SpriteRenderer spriteRenderer = root.GetComponent<SpriteRenderer>();
        spriteRenderer.sprite = AssetDatabase.LoadAllAssetsAtPath(GolemSheetPath).OfType<Sprite>().First(s => s.name == "golem_walk_0");
        root.AddComponent<Animator>().runtimeAnimatorController = controller;

        // Sprite'ın boş kenarları hariç gövdeye oturan kutu
        BoxCollider2D box = root.GetComponent<BoxCollider2D>();
        box.size = new Vector2(0.8f, 0.5f);
        box.offset = new Vector2(0f, -0.05f);

        EnemyController enemy = root.GetComponent<EnemyController>();
        enemy.health = 40;
        enemy.speed = 1.5f;
        enemy.despawnDistance = 200f; // Yavaş olduğu için geride kalınca silinmesin
        enemy.xpReward = 5;

        GameObject prefab = PrefabUtility.SaveAsPrefabAsset(root, GolemPrefabPath);
        PrefabUtility.UnloadPrefabContents(root);
        return prefab;
    }
}
