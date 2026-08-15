namespace MyDent.Model.Enums
{
    // The three legs of the hybrid recommender (see recommender-dokumentacija.md):
    // Popularity = fallback for patients with no visit history yet, ContentBased = based on the
    // patient's own service-category history, TimeBased = a recurring service is due again.
    public enum RecommendationReason
    {
        Popularity,
        ContentBased,
        TimeBased
    }
}
